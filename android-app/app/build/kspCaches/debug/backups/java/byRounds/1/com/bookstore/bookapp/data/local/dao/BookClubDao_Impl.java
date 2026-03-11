package com.bookstore.bookapp.data.local.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.bookstore.bookapp.data.local.Converters;
import com.bookstore.bookapp.data.local.entity.BookClubEntity;
import com.bookstore.bookapp.domain.model.GroupCategory;
import com.bookstore.bookapp.domain.model.MemberRole;
import com.bookstore.bookapp.domain.model.PrivacySetting;
import java.lang.Class;
import java.lang.Double;
import java.lang.Exception;
import java.lang.IllegalStateException;
import java.lang.Long;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class BookClubDao_Impl implements BookClubDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<BookClubEntity> __insertionAdapterOfBookClubEntity;

  private final Converters __converters = new Converters();

  private final SharedSQLiteStatement __preparedStmtOfClearMyGroups;

  private final SharedSQLiteStatement __preparedStmtOfClearDiscoveredGroups;

  private final SharedSQLiteStatement __preparedStmtOfClearAll;

  public BookClubDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfBookClubEntity = new EntityInsertionAdapter<BookClubEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `book_clubs` (`id`,`name`,`description`,`coverImageUrl`,`category`,`privacy`,`creatorId`,`inviteCode`,`inviteCodeExpiry`,`rules`,`booksCount`,`memberCount`,`role`,`isMember`,`joinedAt`,`distance`,`createdAt`,`updatedAt`,`isMyGroup`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final BookClubEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getName());
        statement.bindString(3, entity.getDescription());
        if (entity.getCoverImageUrl() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getCoverImageUrl());
        }
        final String _tmp = __converters.toGroupCategory(entity.getCategory());
        statement.bindString(5, _tmp);
        final String _tmp_1 = __converters.toPrivacySetting(entity.getPrivacy());
        statement.bindString(6, _tmp_1);
        statement.bindString(7, entity.getCreatorId());
        statement.bindString(8, entity.getInviteCode());
        final Long _tmp_2 = __converters.dateToTimestamp(entity.getInviteCodeExpiry());
        if (_tmp_2 == null) {
          statement.bindNull(9);
        } else {
          statement.bindLong(9, _tmp_2);
        }
        if (entity.getRules() == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, entity.getRules());
        }
        statement.bindLong(11, entity.getBooksCount());
        statement.bindLong(12, entity.getMemberCount());
        final String _tmp_3 = __converters.toMemberRole(entity.getRole());
        if (_tmp_3 == null) {
          statement.bindNull(13);
        } else {
          statement.bindString(13, _tmp_3);
        }
        final int _tmp_4 = entity.isMember() ? 1 : 0;
        statement.bindLong(14, _tmp_4);
        final Long _tmp_5 = __converters.dateToTimestamp(entity.getJoinedAt());
        if (_tmp_5 == null) {
          statement.bindNull(15);
        } else {
          statement.bindLong(15, _tmp_5);
        }
        if (entity.getDistance() == null) {
          statement.bindNull(16);
        } else {
          statement.bindDouble(16, entity.getDistance());
        }
        final Long _tmp_6 = __converters.dateToTimestamp(entity.getCreatedAt());
        if (_tmp_6 == null) {
          statement.bindNull(17);
        } else {
          statement.bindLong(17, _tmp_6);
        }
        final Long _tmp_7 = __converters.dateToTimestamp(entity.getUpdatedAt());
        if (_tmp_7 == null) {
          statement.bindNull(18);
        } else {
          statement.bindLong(18, _tmp_7);
        }
        final int _tmp_8 = entity.isMyGroup() ? 1 : 0;
        statement.bindLong(19, _tmp_8);
      }
    };
    this.__preparedStmtOfClearMyGroups = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM book_clubs WHERE isMyGroup = 1";
        return _query;
      }
    };
    this.__preparedStmtOfClearDiscoveredGroups = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM book_clubs WHERE isMyGroup = 0";
        return _query;
      }
    };
    this.__preparedStmtOfClearAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM book_clubs";
        return _query;
      }
    };
  }

  @Override
  public Object insertGroups(final List<BookClubEntity> groups,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfBookClubEntity.insert(groups);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object insertGroup(final BookClubEntity group,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfBookClubEntity.insert(group);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object clearMyGroups(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearMyGroups.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfClearMyGroups.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object clearDiscoveredGroups(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearDiscoveredGroups.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfClearDiscoveredGroups.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object clearAll(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearAll.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfClearAll.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<BookClubEntity>> getMyGroups() {
    final String _sql = "SELECT * FROM book_clubs WHERE isMyGroup = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"book_clubs"}, new Callable<List<BookClubEntity>>() {
      @Override
      @NonNull
      public List<BookClubEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfCoverImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "coverImageUrl");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfPrivacy = CursorUtil.getColumnIndexOrThrow(_cursor, "privacy");
          final int _cursorIndexOfCreatorId = CursorUtil.getColumnIndexOrThrow(_cursor, "creatorId");
          final int _cursorIndexOfInviteCode = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCode");
          final int _cursorIndexOfInviteCodeExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCodeExpiry");
          final int _cursorIndexOfRules = CursorUtil.getColumnIndexOrThrow(_cursor, "rules");
          final int _cursorIndexOfBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "booksCount");
          final int _cursorIndexOfMemberCount = CursorUtil.getColumnIndexOrThrow(_cursor, "memberCount");
          final int _cursorIndexOfRole = CursorUtil.getColumnIndexOrThrow(_cursor, "role");
          final int _cursorIndexOfIsMember = CursorUtil.getColumnIndexOrThrow(_cursor, "isMember");
          final int _cursorIndexOfJoinedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "joinedAt");
          final int _cursorIndexOfDistance = CursorUtil.getColumnIndexOrThrow(_cursor, "distance");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyGroup");
          final List<BookClubEntity> _result = new ArrayList<BookClubEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final BookClubEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpCoverImageUrl;
            if (_cursor.isNull(_cursorIndexOfCoverImageUrl)) {
              _tmpCoverImageUrl = null;
            } else {
              _tmpCoverImageUrl = _cursor.getString(_cursorIndexOfCoverImageUrl);
            }
            final GroupCategory _tmpCategory;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCategory);
            _tmpCategory = __converters.fromGroupCategory(_tmp);
            final PrivacySetting _tmpPrivacy;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfPrivacy);
            _tmpPrivacy = __converters.fromPrivacySetting(_tmp_1);
            final String _tmpCreatorId;
            _tmpCreatorId = _cursor.getString(_cursorIndexOfCreatorId);
            final String _tmpInviteCode;
            _tmpInviteCode = _cursor.getString(_cursorIndexOfInviteCode);
            final Date _tmpInviteCodeExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfInviteCodeExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfInviteCodeExpiry);
            }
            _tmpInviteCodeExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpRules;
            if (_cursor.isNull(_cursorIndexOfRules)) {
              _tmpRules = null;
            } else {
              _tmpRules = _cursor.getString(_cursorIndexOfRules);
            }
            final int _tmpBooksCount;
            _tmpBooksCount = _cursor.getInt(_cursorIndexOfBooksCount);
            final int _tmpMemberCount;
            _tmpMemberCount = _cursor.getInt(_cursorIndexOfMemberCount);
            final MemberRole _tmpRole;
            final String _tmp_3;
            if (_cursor.isNull(_cursorIndexOfRole)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getString(_cursorIndexOfRole);
            }
            _tmpRole = __converters.fromMemberRole(_tmp_3);
            final boolean _tmpIsMember;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfIsMember);
            _tmpIsMember = _tmp_4 != 0;
            final Date _tmpJoinedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfJoinedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfJoinedAt);
            }
            _tmpJoinedAt = __converters.fromTimestamp(_tmp_5);
            final Double _tmpDistance;
            if (_cursor.isNull(_cursorIndexOfDistance)) {
              _tmpDistance = null;
            } else {
              _tmpDistance = _cursor.getDouble(_cursorIndexOfDistance);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_7 = __converters.fromTimestamp(_tmp_6);
            if (_tmp_7 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_7;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_8);
            final boolean _tmpIsMyGroup;
            final int _tmp_9;
            _tmp_9 = _cursor.getInt(_cursorIndexOfIsMyGroup);
            _tmpIsMyGroup = _tmp_9 != 0;
            _item = new BookClubEntity(_tmpId,_tmpName,_tmpDescription,_tmpCoverImageUrl,_tmpCategory,_tmpPrivacy,_tmpCreatorId,_tmpInviteCode,_tmpInviteCodeExpiry,_tmpRules,_tmpBooksCount,_tmpMemberCount,_tmpRole,_tmpIsMember,_tmpJoinedAt,_tmpDistance,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyGroup);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Flow<List<BookClubEntity>> getDiscoveredGroups() {
    final String _sql = "SELECT * FROM book_clubs WHERE isMyGroup = 0";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"book_clubs"}, new Callable<List<BookClubEntity>>() {
      @Override
      @NonNull
      public List<BookClubEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfCoverImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "coverImageUrl");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfPrivacy = CursorUtil.getColumnIndexOrThrow(_cursor, "privacy");
          final int _cursorIndexOfCreatorId = CursorUtil.getColumnIndexOrThrow(_cursor, "creatorId");
          final int _cursorIndexOfInviteCode = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCode");
          final int _cursorIndexOfInviteCodeExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCodeExpiry");
          final int _cursorIndexOfRules = CursorUtil.getColumnIndexOrThrow(_cursor, "rules");
          final int _cursorIndexOfBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "booksCount");
          final int _cursorIndexOfMemberCount = CursorUtil.getColumnIndexOrThrow(_cursor, "memberCount");
          final int _cursorIndexOfRole = CursorUtil.getColumnIndexOrThrow(_cursor, "role");
          final int _cursorIndexOfIsMember = CursorUtil.getColumnIndexOrThrow(_cursor, "isMember");
          final int _cursorIndexOfJoinedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "joinedAt");
          final int _cursorIndexOfDistance = CursorUtil.getColumnIndexOrThrow(_cursor, "distance");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyGroup");
          final List<BookClubEntity> _result = new ArrayList<BookClubEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final BookClubEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpCoverImageUrl;
            if (_cursor.isNull(_cursorIndexOfCoverImageUrl)) {
              _tmpCoverImageUrl = null;
            } else {
              _tmpCoverImageUrl = _cursor.getString(_cursorIndexOfCoverImageUrl);
            }
            final GroupCategory _tmpCategory;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCategory);
            _tmpCategory = __converters.fromGroupCategory(_tmp);
            final PrivacySetting _tmpPrivacy;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfPrivacy);
            _tmpPrivacy = __converters.fromPrivacySetting(_tmp_1);
            final String _tmpCreatorId;
            _tmpCreatorId = _cursor.getString(_cursorIndexOfCreatorId);
            final String _tmpInviteCode;
            _tmpInviteCode = _cursor.getString(_cursorIndexOfInviteCode);
            final Date _tmpInviteCodeExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfInviteCodeExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfInviteCodeExpiry);
            }
            _tmpInviteCodeExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpRules;
            if (_cursor.isNull(_cursorIndexOfRules)) {
              _tmpRules = null;
            } else {
              _tmpRules = _cursor.getString(_cursorIndexOfRules);
            }
            final int _tmpBooksCount;
            _tmpBooksCount = _cursor.getInt(_cursorIndexOfBooksCount);
            final int _tmpMemberCount;
            _tmpMemberCount = _cursor.getInt(_cursorIndexOfMemberCount);
            final MemberRole _tmpRole;
            final String _tmp_3;
            if (_cursor.isNull(_cursorIndexOfRole)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getString(_cursorIndexOfRole);
            }
            _tmpRole = __converters.fromMemberRole(_tmp_3);
            final boolean _tmpIsMember;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfIsMember);
            _tmpIsMember = _tmp_4 != 0;
            final Date _tmpJoinedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfJoinedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfJoinedAt);
            }
            _tmpJoinedAt = __converters.fromTimestamp(_tmp_5);
            final Double _tmpDistance;
            if (_cursor.isNull(_cursorIndexOfDistance)) {
              _tmpDistance = null;
            } else {
              _tmpDistance = _cursor.getDouble(_cursorIndexOfDistance);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_7 = __converters.fromTimestamp(_tmp_6);
            if (_tmp_7 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_7;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_8);
            final boolean _tmpIsMyGroup;
            final int _tmp_9;
            _tmp_9 = _cursor.getInt(_cursorIndexOfIsMyGroup);
            _tmpIsMyGroup = _tmp_9 != 0;
            _item = new BookClubEntity(_tmpId,_tmpName,_tmpDescription,_tmpCoverImageUrl,_tmpCategory,_tmpPrivacy,_tmpCreatorId,_tmpInviteCode,_tmpInviteCodeExpiry,_tmpRules,_tmpBooksCount,_tmpMemberCount,_tmpRole,_tmpIsMember,_tmpJoinedAt,_tmpDistance,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyGroup);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getGroupById(final String id,
      final Continuation<? super BookClubEntity> $completion) {
    final String _sql = "SELECT * FROM book_clubs WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<BookClubEntity>() {
      @Override
      @Nullable
      public BookClubEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfName = CursorUtil.getColumnIndexOrThrow(_cursor, "name");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfCoverImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "coverImageUrl");
          final int _cursorIndexOfCategory = CursorUtil.getColumnIndexOrThrow(_cursor, "category");
          final int _cursorIndexOfPrivacy = CursorUtil.getColumnIndexOrThrow(_cursor, "privacy");
          final int _cursorIndexOfCreatorId = CursorUtil.getColumnIndexOrThrow(_cursor, "creatorId");
          final int _cursorIndexOfInviteCode = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCode");
          final int _cursorIndexOfInviteCodeExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "inviteCodeExpiry");
          final int _cursorIndexOfRules = CursorUtil.getColumnIndexOrThrow(_cursor, "rules");
          final int _cursorIndexOfBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "booksCount");
          final int _cursorIndexOfMemberCount = CursorUtil.getColumnIndexOrThrow(_cursor, "memberCount");
          final int _cursorIndexOfRole = CursorUtil.getColumnIndexOrThrow(_cursor, "role");
          final int _cursorIndexOfIsMember = CursorUtil.getColumnIndexOrThrow(_cursor, "isMember");
          final int _cursorIndexOfJoinedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "joinedAt");
          final int _cursorIndexOfDistance = CursorUtil.getColumnIndexOrThrow(_cursor, "distance");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyGroup");
          final BookClubEntity _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpName;
            _tmpName = _cursor.getString(_cursorIndexOfName);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpCoverImageUrl;
            if (_cursor.isNull(_cursorIndexOfCoverImageUrl)) {
              _tmpCoverImageUrl = null;
            } else {
              _tmpCoverImageUrl = _cursor.getString(_cursorIndexOfCoverImageUrl);
            }
            final GroupCategory _tmpCategory;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCategory);
            _tmpCategory = __converters.fromGroupCategory(_tmp);
            final PrivacySetting _tmpPrivacy;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfPrivacy);
            _tmpPrivacy = __converters.fromPrivacySetting(_tmp_1);
            final String _tmpCreatorId;
            _tmpCreatorId = _cursor.getString(_cursorIndexOfCreatorId);
            final String _tmpInviteCode;
            _tmpInviteCode = _cursor.getString(_cursorIndexOfInviteCode);
            final Date _tmpInviteCodeExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfInviteCodeExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfInviteCodeExpiry);
            }
            _tmpInviteCodeExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpRules;
            if (_cursor.isNull(_cursorIndexOfRules)) {
              _tmpRules = null;
            } else {
              _tmpRules = _cursor.getString(_cursorIndexOfRules);
            }
            final int _tmpBooksCount;
            _tmpBooksCount = _cursor.getInt(_cursorIndexOfBooksCount);
            final int _tmpMemberCount;
            _tmpMemberCount = _cursor.getInt(_cursorIndexOfMemberCount);
            final MemberRole _tmpRole;
            final String _tmp_3;
            if (_cursor.isNull(_cursorIndexOfRole)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getString(_cursorIndexOfRole);
            }
            _tmpRole = __converters.fromMemberRole(_tmp_3);
            final boolean _tmpIsMember;
            final int _tmp_4;
            _tmp_4 = _cursor.getInt(_cursorIndexOfIsMember);
            _tmpIsMember = _tmp_4 != 0;
            final Date _tmpJoinedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfJoinedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfJoinedAt);
            }
            _tmpJoinedAt = __converters.fromTimestamp(_tmp_5);
            final Double _tmpDistance;
            if (_cursor.isNull(_cursorIndexOfDistance)) {
              _tmpDistance = null;
            } else {
              _tmpDistance = _cursor.getDouble(_cursorIndexOfDistance);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_7 = __converters.fromTimestamp(_tmp_6);
            if (_tmp_7 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_7;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_8);
            final boolean _tmpIsMyGroup;
            final int _tmp_9;
            _tmp_9 = _cursor.getInt(_cursorIndexOfIsMyGroup);
            _tmpIsMyGroup = _tmp_9 != 0;
            _result = new BookClubEntity(_tmpId,_tmpName,_tmpDescription,_tmpCoverImageUrl,_tmpCategory,_tmpPrivacy,_tmpCreatorId,_tmpInviteCode,_tmpInviteCodeExpiry,_tmpRules,_tmpBooksCount,_tmpMemberCount,_tmpRole,_tmpIsMember,_tmpJoinedAt,_tmpDistance,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyGroup);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
