import prisma from './src/config/database';
import { getUserGroups, getGroupById, updateGroup, createGroup } from './src/services/group.service';
import { GroupCategory, PrivacySetting, MemberRole } from '@prisma/client';

async function verifyContract() {
    console.log('--- Verifying Group API Contract ---');

    // 1. Setup - Create a test user and group
    const testUserId = 'test-user-' + Date.now();
    await prisma.user.create({
        data: {
            id: testUserId,
            phoneNumber: '+1' + Math.floor(1000000000 + Math.random() * 9000000000),
            name: 'Test User',
        }
    });

    console.log('Creating test group...');
    const group = await createGroup({
        name: 'Verification Group',
        description: 'Testing API contract',
        category: GroupCategory.BOOK_CLUB,
        privacy: PrivacySetting.PUBLIC,
        creatorId: testUserId
    });

    console.log('1. createGroup response keys:', Object.keys(group));
    if ('role' in group) {
        console.log('SUCCESS: role found in createGroup');
    } else {
        console.log('FAIL: role NOT found in createGroup');
    }

    // 2. Verify getUserGroups
    const userGroups = await getUserGroups(testUserId);
    console.log('2. getUserGroups response keys (first item):', Object.keys(userGroups[0]));
    if ('role' in userGroups[0]) {
        console.log('SUCCESS: role found in getUserGroups');
    } else {
        console.log('FAIL: role NOT found in getUserGroups');
    }

    // 3. Verify getGroupById
    const groupDetails = await getGroupById(group.id, testUserId);
    if (!groupDetails) throw new Error('Group not found');
    console.log('3. getGroupById response keys:', Object.keys(groupDetails));
    if ('role' in groupDetails) {
        console.log('SUCCESS: role found in getGroupById');
    } else {
        console.log('FAIL: role NOT found in getGroupById');
    }

    // 4. Verify updateGroup
    const updated = await updateGroup(group.id, testUserId, { name: 'Updated Name' });
    console.log('4. updateGroup response keys:', Object.keys(updated));
    if ('role' in updated) {
        console.log('SUCCESS: role found in updateGroup');
    } else {
        console.log('FAIL: role NOT found in updateGroup');
    }

    // Cleanup
    await prisma.user.delete({ where: { id: testUserId } });
    console.log('--- Verification Complete ---');
}

verifyContract()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
