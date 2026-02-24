// Mock Prisma
jest.mock('../../src/config/database', () => require('../__mocks__/prisma').default);

import prismaMock from '../__mocks__/prisma';
import {
    createGroup,
    getGroupById,
    getUserGroups,
    joinGroup,
    leaveGroup,
    updateGroup,
    deleteGroup,
} from '../../src/services/group.service';

const baseGroup = {
    id: 'group-1',
    name: 'Fiction Lovers',
    description: 'A group for fiction enthusiasts',
    category: 'FICTION' as any,
    privacy: 'PUBLIC' as any,
    creatorId: 'user-1',
    inviteCode: 'ABCD1234',
    inviteCodeExpiry: null,
    coverImageUrl: null,
    rules: null,
    memberCount: 1,
    booksCount: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
    creator: { id: 'user-1', name: 'Alice', profileImageUrl: null },
    members: [{ role: 'CREATOR', joinedAt: new Date() }],
};

describe('createGroup', () => {
    it('creates a group and includes the creator role in the response', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(null); // no collision
        (prismaMock.group.create as jest.Mock).mockResolvedValue(baseGroup);

        const result = await createGroup({
            name: 'Fiction Lovers',
            description: 'A group for fiction enthusiasts',
            category: 'FICTION' as any,
            privacy: 'PUBLIC' as any,
            creatorId: 'user-1',
        });

        expect(prismaMock.group.create).toHaveBeenCalled();
        expect(result.role).toBe('CREATOR');
        expect(result.name).toBe('Fiction Lovers');
    });
});

describe('getGroupById', () => {
    it('returns null when group is not found', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(null);

        const result = await getGroupById('nonexistent');
        expect(result).toBeNull();
    });

    it('returns null for a PRIVATE group when the user is not a member', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue({
            ...baseGroup,
            privacy: 'PRIVATE',
            creatorId: 'other-user',
            members: [], // user-2 is not a member
        });

        const result = await getGroupById('group-1', 'user-2');
        expect(result).toBeNull();
    });

    it('returns group data for a member of a PRIVATE group', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue({
            ...baseGroup,
            privacy: 'PRIVATE',
            creatorId: 'other-user',
            members: [{ role: 'MEMBER' }],
        });

        const result = await getGroupById('group-1', 'user-2');
        expect(result).not.toBeNull();
        expect(result?.isMember).toBe(true);
    });

    it('returns group data for a PUBLIC group without login', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue({
            ...baseGroup,
            members: [],
        });

        const result = await getGroupById('group-1');
        expect(result).not.toBeNull();
    });
});

describe('joinGroup', () => {
    it('throws "Invalid invite code" when no group is found', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(joinGroup('BADCODE', 'user-2')).rejects.toThrow('Invalid invite code');
    });

    it('throws when invite code is expired', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue({
            ...baseGroup,
            inviteCodeExpiry: new Date('2000-01-01'), // expired
        });

        await expect(joinGroup('ABCD1234', 'user-2')).rejects.toThrow('Invite code has expired');
    });

    it('throws "already a member" when user is already in the group', async () => {
        (prismaMock.group.findUnique as jest.Mock)
            .mockResolvedValueOnce(baseGroup) // find group by invite code
            .mockResolvedValueOnce(null);     // invite code uniqueness check (unused here)
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue({ userId: 'user-2', role: 'MEMBER' });

        await expect(joinGroup('ABCD1234', 'user-2')).rejects.toThrow('already a member');
    });

    it('successfully adds a new member and increments memberCount', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(baseGroup);
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue(null);
        (prismaMock.groupMember.create as jest.Mock).mockResolvedValue({});
        (prismaMock.group.update as jest.Mock).mockResolvedValue({
            ...baseGroup,
            memberCount: 2,
        });

        const result = await joinGroup('ABCD1234', 'user-2');

        expect(prismaMock.groupMember.create).toHaveBeenCalled();
        expect(prismaMock.group.update).toHaveBeenCalledWith(
            expect.objectContaining({ data: { memberCount: { increment: 1 } } })
        );
        expect(result.role).toBe('MEMBER');
    });
});

describe('leaveGroup', () => {
    it('throws "not a member" when user has no membership', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(leaveGroup('group-1', 'user-2')).rejects.toThrow('not a member');
    });

    it('throws when the creator tries to leave', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue({
            role: 'CREATOR',
        });

        await expect(leaveGroup('group-1', 'user-1')).rejects.toThrow('Creator cannot leave');
    });

    it('removes member, their books, and decrements member count', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue({ role: 'MEMBER' });
        (prismaMock.bookGroup.findMany as jest.Mock).mockResolvedValue([]);
        (prismaMock.groupMember.delete as jest.Mock).mockResolvedValue({});
        (prismaMock.group.update as jest.Mock).mockResolvedValue({});

        await leaveGroup('group-1', 'user-2');

        expect(prismaMock.groupMember.delete).toHaveBeenCalled();
        expect(prismaMock.group.update).toHaveBeenCalledWith(
            expect.objectContaining({ data: { memberCount: { decrement: 1 } } })
        );
    });
});

describe('updateGroup', () => {
    it('throws when user is not a member of the group', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(
            updateGroup('group-1', 'user-2', { name: 'New Name' })
        ).rejects.toThrow('not a member');
    });

    it('throws when user is a regular MEMBER (not ADMIN or CREATOR)', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue({ role: 'MEMBER' });

        await expect(
            updateGroup('group-1', 'user-2', { name: 'New Name' })
        ).rejects.toThrow('Only admins and creators');
    });

    it('updates group data when requester is the CREATOR', async () => {
        (prismaMock.groupMember.findUnique as jest.Mock).mockResolvedValue({ role: 'CREATOR' });
        (prismaMock.group.update as jest.Mock).mockResolvedValue({
            ...baseGroup,
            name: 'Updated Name',
            creator: baseGroup.creator,
        });

        const result = await updateGroup('group-1', 'user-1', { name: 'Updated Name' });

        expect(prismaMock.group.update).toHaveBeenCalled();
        expect(result.name).toBe('Updated Name');
    });
});

describe('deleteGroup', () => {
    it('throws "Group not found" when the group does not exist', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(deleteGroup('group-1', 'user-1')).rejects.toThrow('Group not found');
    });

    it('throws "Only the creator can delete" when requester is not the creator', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue({
            ...baseGroup,
            creatorId: 'actual-creator',
        });

        await expect(deleteGroup('group-1', 'other-user')).rejects.toThrow('Only the creator can delete');
    });

    it('deletes the group when requester is the creator', async () => {
        (prismaMock.group.findUnique as jest.Mock).mockResolvedValue(baseGroup);
        (prismaMock.group.delete as jest.Mock).mockResolvedValue({});

        await deleteGroup('group-1', 'user-1');

        expect(prismaMock.group.delete).toHaveBeenCalledWith({ where: { id: 'group-1' } });
    });
});

describe('getUserGroups', () => {
    it('returns groups mapped with role and joinedAt', async () => {
        (prismaMock.group.findMany as jest.Mock).mockResolvedValue([
            {
                ...baseGroup,
                members: [{ role: 'CREATOR', joinedAt: new Date() }],
            },
        ]);

        const result = await getUserGroups('user-1');

        expect(result).toHaveLength(1);
        expect(result[0].role).toBe('CREATOR');
        expect(result[0].members).toBeUndefined();
    });
});
