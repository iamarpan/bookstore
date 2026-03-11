package com.bookstore.bookapp.data.local.dao;

import android.database.Cursor;
import androidx.annotation.NonNull;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.bookstore.bookapp.data.local.Converters;
import com.bookstore.bookapp.data.local.entity.PaymentStatusEntity;
import com.bookstore.bookapp.data.local.entity.TransactionEntity;
import com.bookstore.bookapp.domain.model.BorrowDuration;
import com.bookstore.bookapp.domain.model.TransactionStatus;
import java.lang.Class;
import java.lang.Exception;
import java.lang.IllegalStateException;
import java.lang.Integer;
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
public final class TransactionDao_Impl implements TransactionDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<TransactionEntity> __insertionAdapterOfTransactionEntity;

  private final Converters __converters = new Converters();

  private final SharedSQLiteStatement __preparedStmtOfClearBorrowerTransactions;

  private final SharedSQLiteStatement __preparedStmtOfClearOwnerTransactions;

  private final SharedSQLiteStatement __preparedStmtOfClearHistoryTransactions;

  private final SharedSQLiteStatement __preparedStmtOfClearAll;

  public TransactionDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfTransactionEntity = new EntityInsertionAdapter<TransactionEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `transactions` (`id`,`bookId`,`bookTitle`,`bookImageUrl`,`borrowerId`,`borrowerName`,`borrowerProfileImageUrl`,`ownerId`,`ownerName`,`ownerProfileImageUrl`,`groupId`,`status`,`duration`,`durationDays`,`lendingFee`,`requestMessage`,`rejectionReason`,`handoverOTP`,`handoverOTPExpiry`,`returnOTP`,`returnOTPExpiry`,`requestedAt`,`approvedAt`,`handoverAt`,`dueDate`,`returnedAt`,`ownerRating`,`ownerComment`,`borrowerRating`,`borrowerComment`,`bookConditionRating`,`isBorrowerTxn`,`isOwnerTxn`,`isHistoryTxn`,`borrowerConfirmed`,`ownerConfirmed`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final TransactionEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getBookId());
        statement.bindString(3, entity.getBookTitle());
        if (entity.getBookImageUrl() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getBookImageUrl());
        }
        statement.bindString(5, entity.getBorrowerId());
        statement.bindString(6, entity.getBorrowerName());
        if (entity.getBorrowerProfileImageUrl() == null) {
          statement.bindNull(7);
        } else {
          statement.bindString(7, entity.getBorrowerProfileImageUrl());
        }
        statement.bindString(8, entity.getOwnerId());
        statement.bindString(9, entity.getOwnerName());
        if (entity.getOwnerProfileImageUrl() == null) {
          statement.bindNull(10);
        } else {
          statement.bindString(10, entity.getOwnerProfileImageUrl());
        }
        statement.bindString(11, entity.getGroupId());
        final String _tmp = __converters.toTransactionStatus(entity.getStatus());
        statement.bindString(12, _tmp);
        final String _tmp_1 = __converters.toBorrowDuration(entity.getDuration());
        statement.bindString(13, _tmp_1);
        statement.bindLong(14, entity.getDurationDays());
        statement.bindDouble(15, entity.getLendingFee());
        if (entity.getRequestMessage() == null) {
          statement.bindNull(16);
        } else {
          statement.bindString(16, entity.getRequestMessage());
        }
        if (entity.getRejectionReason() == null) {
          statement.bindNull(17);
        } else {
          statement.bindString(17, entity.getRejectionReason());
        }
        if (entity.getHandoverOTP() == null) {
          statement.bindNull(18);
        } else {
          statement.bindString(18, entity.getHandoverOTP());
        }
        final Long _tmp_2 = __converters.dateToTimestamp(entity.getHandoverOTPExpiry());
        if (_tmp_2 == null) {
          statement.bindNull(19);
        } else {
          statement.bindLong(19, _tmp_2);
        }
        if (entity.getReturnOTP() == null) {
          statement.bindNull(20);
        } else {
          statement.bindString(20, entity.getReturnOTP());
        }
        final Long _tmp_3 = __converters.dateToTimestamp(entity.getReturnOTPExpiry());
        if (_tmp_3 == null) {
          statement.bindNull(21);
        } else {
          statement.bindLong(21, _tmp_3);
        }
        final Long _tmp_4 = __converters.dateToTimestamp(entity.getRequestedAt());
        if (_tmp_4 == null) {
          statement.bindNull(22);
        } else {
          statement.bindLong(22, _tmp_4);
        }
        final Long _tmp_5 = __converters.dateToTimestamp(entity.getApprovedAt());
        if (_tmp_5 == null) {
          statement.bindNull(23);
        } else {
          statement.bindLong(23, _tmp_5);
        }
        final Long _tmp_6 = __converters.dateToTimestamp(entity.getHandoverAt());
        if (_tmp_6 == null) {
          statement.bindNull(24);
        } else {
          statement.bindLong(24, _tmp_6);
        }
        final Long _tmp_7 = __converters.dateToTimestamp(entity.getDueDate());
        if (_tmp_7 == null) {
          statement.bindNull(25);
        } else {
          statement.bindLong(25, _tmp_7);
        }
        final Long _tmp_8 = __converters.dateToTimestamp(entity.getReturnedAt());
        if (_tmp_8 == null) {
          statement.bindNull(26);
        } else {
          statement.bindLong(26, _tmp_8);
        }
        if (entity.getOwnerRating() == null) {
          statement.bindNull(27);
        } else {
          statement.bindLong(27, entity.getOwnerRating());
        }
        if (entity.getOwnerComment() == null) {
          statement.bindNull(28);
        } else {
          statement.bindString(28, entity.getOwnerComment());
        }
        if (entity.getBorrowerRating() == null) {
          statement.bindNull(29);
        } else {
          statement.bindLong(29, entity.getBorrowerRating());
        }
        if (entity.getBorrowerComment() == null) {
          statement.bindNull(30);
        } else {
          statement.bindString(30, entity.getBorrowerComment());
        }
        if (entity.getBookConditionRating() == null) {
          statement.bindNull(31);
        } else {
          statement.bindLong(31, entity.getBookConditionRating());
        }
        final int _tmp_9 = entity.isBorrowerTxn() ? 1 : 0;
        statement.bindLong(32, _tmp_9);
        final int _tmp_10 = entity.isOwnerTxn() ? 1 : 0;
        statement.bindLong(33, _tmp_10);
        final int _tmp_11 = entity.isHistoryTxn() ? 1 : 0;
        statement.bindLong(34, _tmp_11);
        final PaymentStatusEntity _tmpPaymentStatus = entity.getPaymentStatus();
        final int _tmp_12 = _tmpPaymentStatus.getBorrowerConfirmed() ? 1 : 0;
        statement.bindLong(35, _tmp_12);
        final int _tmp_13 = _tmpPaymentStatus.getOwnerConfirmed() ? 1 : 0;
        statement.bindLong(36, _tmp_13);
      }
    };
    this.__preparedStmtOfClearBorrowerTransactions = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM transactions WHERE isBorrowerTxn = 1";
        return _query;
      }
    };
    this.__preparedStmtOfClearOwnerTransactions = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM transactions WHERE isOwnerTxn = 1";
        return _query;
      }
    };
    this.__preparedStmtOfClearHistoryTransactions = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM transactions WHERE isHistoryTxn = 1";
        return _query;
      }
    };
    this.__preparedStmtOfClearAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM transactions";
        return _query;
      }
    };
  }

  @Override
  public Object insertTransactions(final List<TransactionEntity> transactions,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfTransactionEntity.insert(transactions);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object clearBorrowerTransactions(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearBorrowerTransactions.acquire();
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
          __preparedStmtOfClearBorrowerTransactions.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object clearOwnerTransactions(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearOwnerTransactions.acquire();
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
          __preparedStmtOfClearOwnerTransactions.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object clearHistoryTransactions(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearHistoryTransactions.acquire();
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
          __preparedStmtOfClearHistoryTransactions.release(_stmt);
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
  public Flow<List<TransactionEntity>> getBorrowerTransactions() {
    final String _sql = "SELECT * FROM transactions WHERE isBorrowerTxn = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"transactions"}, new Callable<List<TransactionEntity>>() {
      @Override
      @NonNull
      public List<TransactionEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfBookId = CursorUtil.getColumnIndexOrThrow(_cursor, "bookId");
          final int _cursorIndexOfBookTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "bookTitle");
          final int _cursorIndexOfBookImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "bookImageUrl");
          final int _cursorIndexOfBorrowerId = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerId");
          final int _cursorIndexOfBorrowerName = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerName");
          final int _cursorIndexOfBorrowerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerProfileImageUrl");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfGroupId = CursorUtil.getColumnIndexOrThrow(_cursor, "groupId");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
          final int _cursorIndexOfDurationDays = CursorUtil.getColumnIndexOrThrow(_cursor, "durationDays");
          final int _cursorIndexOfLendingFee = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingFee");
          final int _cursorIndexOfRequestMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "requestMessage");
          final int _cursorIndexOfRejectionReason = CursorUtil.getColumnIndexOrThrow(_cursor, "rejectionReason");
          final int _cursorIndexOfHandoverOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTP");
          final int _cursorIndexOfHandoverOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTPExpiry");
          final int _cursorIndexOfReturnOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTP");
          final int _cursorIndexOfReturnOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTPExpiry");
          final int _cursorIndexOfRequestedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "requestedAt");
          final int _cursorIndexOfApprovedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "approvedAt");
          final int _cursorIndexOfHandoverAt = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverAt");
          final int _cursorIndexOfDueDate = CursorUtil.getColumnIndexOrThrow(_cursor, "dueDate");
          final int _cursorIndexOfReturnedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "returnedAt");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerComment");
          final int _cursorIndexOfBorrowerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerRating");
          final int _cursorIndexOfBorrowerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerComment");
          final int _cursorIndexOfBookConditionRating = CursorUtil.getColumnIndexOrThrow(_cursor, "bookConditionRating");
          final int _cursorIndexOfIsBorrowerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isBorrowerTxn");
          final int _cursorIndexOfIsOwnerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isOwnerTxn");
          final int _cursorIndexOfIsHistoryTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isHistoryTxn");
          final int _cursorIndexOfBorrowerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerConfirmed");
          final int _cursorIndexOfOwnerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerConfirmed");
          final List<TransactionEntity> _result = new ArrayList<TransactionEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final TransactionEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpBookId;
            _tmpBookId = _cursor.getString(_cursorIndexOfBookId);
            final String _tmpBookTitle;
            _tmpBookTitle = _cursor.getString(_cursorIndexOfBookTitle);
            final String _tmpBookImageUrl;
            if (_cursor.isNull(_cursorIndexOfBookImageUrl)) {
              _tmpBookImageUrl = null;
            } else {
              _tmpBookImageUrl = _cursor.getString(_cursorIndexOfBookImageUrl);
            }
            final String _tmpBorrowerId;
            _tmpBorrowerId = _cursor.getString(_cursorIndexOfBorrowerId);
            final String _tmpBorrowerName;
            _tmpBorrowerName = _cursor.getString(_cursorIndexOfBorrowerName);
            final String _tmpBorrowerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfBorrowerProfileImageUrl)) {
              _tmpBorrowerProfileImageUrl = null;
            } else {
              _tmpBorrowerProfileImageUrl = _cursor.getString(_cursorIndexOfBorrowerProfileImageUrl);
            }
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final String _tmpGroupId;
            _tmpGroupId = _cursor.getString(_cursorIndexOfGroupId);
            final TransactionStatus _tmpStatus;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfStatus);
            _tmpStatus = __converters.fromTransactionStatus(_tmp);
            final BorrowDuration _tmpDuration;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfDuration);
            _tmpDuration = __converters.fromBorrowDuration(_tmp_1);
            final int _tmpDurationDays;
            _tmpDurationDays = _cursor.getInt(_cursorIndexOfDurationDays);
            final double _tmpLendingFee;
            _tmpLendingFee = _cursor.getDouble(_cursorIndexOfLendingFee);
            final String _tmpRequestMessage;
            if (_cursor.isNull(_cursorIndexOfRequestMessage)) {
              _tmpRequestMessage = null;
            } else {
              _tmpRequestMessage = _cursor.getString(_cursorIndexOfRequestMessage);
            }
            final String _tmpRejectionReason;
            if (_cursor.isNull(_cursorIndexOfRejectionReason)) {
              _tmpRejectionReason = null;
            } else {
              _tmpRejectionReason = _cursor.getString(_cursorIndexOfRejectionReason);
            }
            final String _tmpHandoverOTP;
            if (_cursor.isNull(_cursorIndexOfHandoverOTP)) {
              _tmpHandoverOTP = null;
            } else {
              _tmpHandoverOTP = _cursor.getString(_cursorIndexOfHandoverOTP);
            }
            final Date _tmpHandoverOTPExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfHandoverOTPExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfHandoverOTPExpiry);
            }
            _tmpHandoverOTPExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpReturnOTP;
            if (_cursor.isNull(_cursorIndexOfReturnOTP)) {
              _tmpReturnOTP = null;
            } else {
              _tmpReturnOTP = _cursor.getString(_cursorIndexOfReturnOTP);
            }
            final Date _tmpReturnOTPExpiry;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfReturnOTPExpiry)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfReturnOTPExpiry);
            }
            _tmpReturnOTPExpiry = __converters.fromTimestamp(_tmp_3);
            final Date _tmpRequestedAt;
            final Long _tmp_4;
            if (_cursor.isNull(_cursorIndexOfRequestedAt)) {
              _tmp_4 = null;
            } else {
              _tmp_4 = _cursor.getLong(_cursorIndexOfRequestedAt);
            }
            final Date _tmp_5 = __converters.fromTimestamp(_tmp_4);
            if (_tmp_5 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpRequestedAt = _tmp_5;
            }
            final Date _tmpApprovedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfApprovedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfApprovedAt);
            }
            _tmpApprovedAt = __converters.fromTimestamp(_tmp_6);
            final Date _tmpHandoverAt;
            final Long _tmp_7;
            if (_cursor.isNull(_cursorIndexOfHandoverAt)) {
              _tmp_7 = null;
            } else {
              _tmp_7 = _cursor.getLong(_cursorIndexOfHandoverAt);
            }
            _tmpHandoverAt = __converters.fromTimestamp(_tmp_7);
            final Date _tmpDueDate;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfDueDate)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfDueDate);
            }
            _tmpDueDate = __converters.fromTimestamp(_tmp_8);
            final Date _tmpReturnedAt;
            final Long _tmp_9;
            if (_cursor.isNull(_cursorIndexOfReturnedAt)) {
              _tmp_9 = null;
            } else {
              _tmp_9 = _cursor.getLong(_cursorIndexOfReturnedAt);
            }
            _tmpReturnedAt = __converters.fromTimestamp(_tmp_9);
            final Integer _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getInt(_cursorIndexOfOwnerRating);
            }
            final String _tmpOwnerComment;
            if (_cursor.isNull(_cursorIndexOfOwnerComment)) {
              _tmpOwnerComment = null;
            } else {
              _tmpOwnerComment = _cursor.getString(_cursorIndexOfOwnerComment);
            }
            final Integer _tmpBorrowerRating;
            if (_cursor.isNull(_cursorIndexOfBorrowerRating)) {
              _tmpBorrowerRating = null;
            } else {
              _tmpBorrowerRating = _cursor.getInt(_cursorIndexOfBorrowerRating);
            }
            final String _tmpBorrowerComment;
            if (_cursor.isNull(_cursorIndexOfBorrowerComment)) {
              _tmpBorrowerComment = null;
            } else {
              _tmpBorrowerComment = _cursor.getString(_cursorIndexOfBorrowerComment);
            }
            final Integer _tmpBookConditionRating;
            if (_cursor.isNull(_cursorIndexOfBookConditionRating)) {
              _tmpBookConditionRating = null;
            } else {
              _tmpBookConditionRating = _cursor.getInt(_cursorIndexOfBookConditionRating);
            }
            final boolean _tmpIsBorrowerTxn;
            final int _tmp_10;
            _tmp_10 = _cursor.getInt(_cursorIndexOfIsBorrowerTxn);
            _tmpIsBorrowerTxn = _tmp_10 != 0;
            final boolean _tmpIsOwnerTxn;
            final int _tmp_11;
            _tmp_11 = _cursor.getInt(_cursorIndexOfIsOwnerTxn);
            _tmpIsOwnerTxn = _tmp_11 != 0;
            final boolean _tmpIsHistoryTxn;
            final int _tmp_12;
            _tmp_12 = _cursor.getInt(_cursorIndexOfIsHistoryTxn);
            _tmpIsHistoryTxn = _tmp_12 != 0;
            final PaymentStatusEntity _tmpPaymentStatus;
            final boolean _tmpBorrowerConfirmed;
            final int _tmp_13;
            _tmp_13 = _cursor.getInt(_cursorIndexOfBorrowerConfirmed);
            _tmpBorrowerConfirmed = _tmp_13 != 0;
            final boolean _tmpOwnerConfirmed;
            final int _tmp_14;
            _tmp_14 = _cursor.getInt(_cursorIndexOfOwnerConfirmed);
            _tmpOwnerConfirmed = _tmp_14 != 0;
            _tmpPaymentStatus = new PaymentStatusEntity(_tmpBorrowerConfirmed,_tmpOwnerConfirmed);
            _item = new TransactionEntity(_tmpId,_tmpBookId,_tmpBookTitle,_tmpBookImageUrl,_tmpBorrowerId,_tmpBorrowerName,_tmpBorrowerProfileImageUrl,_tmpOwnerId,_tmpOwnerName,_tmpOwnerProfileImageUrl,_tmpGroupId,_tmpStatus,_tmpDuration,_tmpDurationDays,_tmpLendingFee,_tmpRequestMessage,_tmpRejectionReason,_tmpHandoverOTP,_tmpHandoverOTPExpiry,_tmpReturnOTP,_tmpReturnOTPExpiry,_tmpPaymentStatus,_tmpRequestedAt,_tmpApprovedAt,_tmpHandoverAt,_tmpDueDate,_tmpReturnedAt,_tmpOwnerRating,_tmpOwnerComment,_tmpBorrowerRating,_tmpBorrowerComment,_tmpBookConditionRating,_tmpIsBorrowerTxn,_tmpIsOwnerTxn,_tmpIsHistoryTxn);
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
  public Flow<List<TransactionEntity>> getOwnerTransactions() {
    final String _sql = "SELECT * FROM transactions WHERE isOwnerTxn = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"transactions"}, new Callable<List<TransactionEntity>>() {
      @Override
      @NonNull
      public List<TransactionEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfBookId = CursorUtil.getColumnIndexOrThrow(_cursor, "bookId");
          final int _cursorIndexOfBookTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "bookTitle");
          final int _cursorIndexOfBookImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "bookImageUrl");
          final int _cursorIndexOfBorrowerId = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerId");
          final int _cursorIndexOfBorrowerName = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerName");
          final int _cursorIndexOfBorrowerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerProfileImageUrl");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfGroupId = CursorUtil.getColumnIndexOrThrow(_cursor, "groupId");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
          final int _cursorIndexOfDurationDays = CursorUtil.getColumnIndexOrThrow(_cursor, "durationDays");
          final int _cursorIndexOfLendingFee = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingFee");
          final int _cursorIndexOfRequestMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "requestMessage");
          final int _cursorIndexOfRejectionReason = CursorUtil.getColumnIndexOrThrow(_cursor, "rejectionReason");
          final int _cursorIndexOfHandoverOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTP");
          final int _cursorIndexOfHandoverOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTPExpiry");
          final int _cursorIndexOfReturnOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTP");
          final int _cursorIndexOfReturnOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTPExpiry");
          final int _cursorIndexOfRequestedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "requestedAt");
          final int _cursorIndexOfApprovedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "approvedAt");
          final int _cursorIndexOfHandoverAt = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverAt");
          final int _cursorIndexOfDueDate = CursorUtil.getColumnIndexOrThrow(_cursor, "dueDate");
          final int _cursorIndexOfReturnedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "returnedAt");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerComment");
          final int _cursorIndexOfBorrowerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerRating");
          final int _cursorIndexOfBorrowerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerComment");
          final int _cursorIndexOfBookConditionRating = CursorUtil.getColumnIndexOrThrow(_cursor, "bookConditionRating");
          final int _cursorIndexOfIsBorrowerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isBorrowerTxn");
          final int _cursorIndexOfIsOwnerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isOwnerTxn");
          final int _cursorIndexOfIsHistoryTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isHistoryTxn");
          final int _cursorIndexOfBorrowerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerConfirmed");
          final int _cursorIndexOfOwnerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerConfirmed");
          final List<TransactionEntity> _result = new ArrayList<TransactionEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final TransactionEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpBookId;
            _tmpBookId = _cursor.getString(_cursorIndexOfBookId);
            final String _tmpBookTitle;
            _tmpBookTitle = _cursor.getString(_cursorIndexOfBookTitle);
            final String _tmpBookImageUrl;
            if (_cursor.isNull(_cursorIndexOfBookImageUrl)) {
              _tmpBookImageUrl = null;
            } else {
              _tmpBookImageUrl = _cursor.getString(_cursorIndexOfBookImageUrl);
            }
            final String _tmpBorrowerId;
            _tmpBorrowerId = _cursor.getString(_cursorIndexOfBorrowerId);
            final String _tmpBorrowerName;
            _tmpBorrowerName = _cursor.getString(_cursorIndexOfBorrowerName);
            final String _tmpBorrowerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfBorrowerProfileImageUrl)) {
              _tmpBorrowerProfileImageUrl = null;
            } else {
              _tmpBorrowerProfileImageUrl = _cursor.getString(_cursorIndexOfBorrowerProfileImageUrl);
            }
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final String _tmpGroupId;
            _tmpGroupId = _cursor.getString(_cursorIndexOfGroupId);
            final TransactionStatus _tmpStatus;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfStatus);
            _tmpStatus = __converters.fromTransactionStatus(_tmp);
            final BorrowDuration _tmpDuration;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfDuration);
            _tmpDuration = __converters.fromBorrowDuration(_tmp_1);
            final int _tmpDurationDays;
            _tmpDurationDays = _cursor.getInt(_cursorIndexOfDurationDays);
            final double _tmpLendingFee;
            _tmpLendingFee = _cursor.getDouble(_cursorIndexOfLendingFee);
            final String _tmpRequestMessage;
            if (_cursor.isNull(_cursorIndexOfRequestMessage)) {
              _tmpRequestMessage = null;
            } else {
              _tmpRequestMessage = _cursor.getString(_cursorIndexOfRequestMessage);
            }
            final String _tmpRejectionReason;
            if (_cursor.isNull(_cursorIndexOfRejectionReason)) {
              _tmpRejectionReason = null;
            } else {
              _tmpRejectionReason = _cursor.getString(_cursorIndexOfRejectionReason);
            }
            final String _tmpHandoverOTP;
            if (_cursor.isNull(_cursorIndexOfHandoverOTP)) {
              _tmpHandoverOTP = null;
            } else {
              _tmpHandoverOTP = _cursor.getString(_cursorIndexOfHandoverOTP);
            }
            final Date _tmpHandoverOTPExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfHandoverOTPExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfHandoverOTPExpiry);
            }
            _tmpHandoverOTPExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpReturnOTP;
            if (_cursor.isNull(_cursorIndexOfReturnOTP)) {
              _tmpReturnOTP = null;
            } else {
              _tmpReturnOTP = _cursor.getString(_cursorIndexOfReturnOTP);
            }
            final Date _tmpReturnOTPExpiry;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfReturnOTPExpiry)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfReturnOTPExpiry);
            }
            _tmpReturnOTPExpiry = __converters.fromTimestamp(_tmp_3);
            final Date _tmpRequestedAt;
            final Long _tmp_4;
            if (_cursor.isNull(_cursorIndexOfRequestedAt)) {
              _tmp_4 = null;
            } else {
              _tmp_4 = _cursor.getLong(_cursorIndexOfRequestedAt);
            }
            final Date _tmp_5 = __converters.fromTimestamp(_tmp_4);
            if (_tmp_5 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpRequestedAt = _tmp_5;
            }
            final Date _tmpApprovedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfApprovedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfApprovedAt);
            }
            _tmpApprovedAt = __converters.fromTimestamp(_tmp_6);
            final Date _tmpHandoverAt;
            final Long _tmp_7;
            if (_cursor.isNull(_cursorIndexOfHandoverAt)) {
              _tmp_7 = null;
            } else {
              _tmp_7 = _cursor.getLong(_cursorIndexOfHandoverAt);
            }
            _tmpHandoverAt = __converters.fromTimestamp(_tmp_7);
            final Date _tmpDueDate;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfDueDate)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfDueDate);
            }
            _tmpDueDate = __converters.fromTimestamp(_tmp_8);
            final Date _tmpReturnedAt;
            final Long _tmp_9;
            if (_cursor.isNull(_cursorIndexOfReturnedAt)) {
              _tmp_9 = null;
            } else {
              _tmp_9 = _cursor.getLong(_cursorIndexOfReturnedAt);
            }
            _tmpReturnedAt = __converters.fromTimestamp(_tmp_9);
            final Integer _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getInt(_cursorIndexOfOwnerRating);
            }
            final String _tmpOwnerComment;
            if (_cursor.isNull(_cursorIndexOfOwnerComment)) {
              _tmpOwnerComment = null;
            } else {
              _tmpOwnerComment = _cursor.getString(_cursorIndexOfOwnerComment);
            }
            final Integer _tmpBorrowerRating;
            if (_cursor.isNull(_cursorIndexOfBorrowerRating)) {
              _tmpBorrowerRating = null;
            } else {
              _tmpBorrowerRating = _cursor.getInt(_cursorIndexOfBorrowerRating);
            }
            final String _tmpBorrowerComment;
            if (_cursor.isNull(_cursorIndexOfBorrowerComment)) {
              _tmpBorrowerComment = null;
            } else {
              _tmpBorrowerComment = _cursor.getString(_cursorIndexOfBorrowerComment);
            }
            final Integer _tmpBookConditionRating;
            if (_cursor.isNull(_cursorIndexOfBookConditionRating)) {
              _tmpBookConditionRating = null;
            } else {
              _tmpBookConditionRating = _cursor.getInt(_cursorIndexOfBookConditionRating);
            }
            final boolean _tmpIsBorrowerTxn;
            final int _tmp_10;
            _tmp_10 = _cursor.getInt(_cursorIndexOfIsBorrowerTxn);
            _tmpIsBorrowerTxn = _tmp_10 != 0;
            final boolean _tmpIsOwnerTxn;
            final int _tmp_11;
            _tmp_11 = _cursor.getInt(_cursorIndexOfIsOwnerTxn);
            _tmpIsOwnerTxn = _tmp_11 != 0;
            final boolean _tmpIsHistoryTxn;
            final int _tmp_12;
            _tmp_12 = _cursor.getInt(_cursorIndexOfIsHistoryTxn);
            _tmpIsHistoryTxn = _tmp_12 != 0;
            final PaymentStatusEntity _tmpPaymentStatus;
            final boolean _tmpBorrowerConfirmed;
            final int _tmp_13;
            _tmp_13 = _cursor.getInt(_cursorIndexOfBorrowerConfirmed);
            _tmpBorrowerConfirmed = _tmp_13 != 0;
            final boolean _tmpOwnerConfirmed;
            final int _tmp_14;
            _tmp_14 = _cursor.getInt(_cursorIndexOfOwnerConfirmed);
            _tmpOwnerConfirmed = _tmp_14 != 0;
            _tmpPaymentStatus = new PaymentStatusEntity(_tmpBorrowerConfirmed,_tmpOwnerConfirmed);
            _item = new TransactionEntity(_tmpId,_tmpBookId,_tmpBookTitle,_tmpBookImageUrl,_tmpBorrowerId,_tmpBorrowerName,_tmpBorrowerProfileImageUrl,_tmpOwnerId,_tmpOwnerName,_tmpOwnerProfileImageUrl,_tmpGroupId,_tmpStatus,_tmpDuration,_tmpDurationDays,_tmpLendingFee,_tmpRequestMessage,_tmpRejectionReason,_tmpHandoverOTP,_tmpHandoverOTPExpiry,_tmpReturnOTP,_tmpReturnOTPExpiry,_tmpPaymentStatus,_tmpRequestedAt,_tmpApprovedAt,_tmpHandoverAt,_tmpDueDate,_tmpReturnedAt,_tmpOwnerRating,_tmpOwnerComment,_tmpBorrowerRating,_tmpBorrowerComment,_tmpBookConditionRating,_tmpIsBorrowerTxn,_tmpIsOwnerTxn,_tmpIsHistoryTxn);
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
  public Flow<List<TransactionEntity>> getHistoryTransactions() {
    final String _sql = "SELECT * FROM transactions WHERE isHistoryTxn = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"transactions"}, new Callable<List<TransactionEntity>>() {
      @Override
      @NonNull
      public List<TransactionEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfBookId = CursorUtil.getColumnIndexOrThrow(_cursor, "bookId");
          final int _cursorIndexOfBookTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "bookTitle");
          final int _cursorIndexOfBookImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "bookImageUrl");
          final int _cursorIndexOfBorrowerId = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerId");
          final int _cursorIndexOfBorrowerName = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerName");
          final int _cursorIndexOfBorrowerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerProfileImageUrl");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfGroupId = CursorUtil.getColumnIndexOrThrow(_cursor, "groupId");
          final int _cursorIndexOfStatus = CursorUtil.getColumnIndexOrThrow(_cursor, "status");
          final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
          final int _cursorIndexOfDurationDays = CursorUtil.getColumnIndexOrThrow(_cursor, "durationDays");
          final int _cursorIndexOfLendingFee = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingFee");
          final int _cursorIndexOfRequestMessage = CursorUtil.getColumnIndexOrThrow(_cursor, "requestMessage");
          final int _cursorIndexOfRejectionReason = CursorUtil.getColumnIndexOrThrow(_cursor, "rejectionReason");
          final int _cursorIndexOfHandoverOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTP");
          final int _cursorIndexOfHandoverOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverOTPExpiry");
          final int _cursorIndexOfReturnOTP = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTP");
          final int _cursorIndexOfReturnOTPExpiry = CursorUtil.getColumnIndexOrThrow(_cursor, "returnOTPExpiry");
          final int _cursorIndexOfRequestedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "requestedAt");
          final int _cursorIndexOfApprovedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "approvedAt");
          final int _cursorIndexOfHandoverAt = CursorUtil.getColumnIndexOrThrow(_cursor, "handoverAt");
          final int _cursorIndexOfDueDate = CursorUtil.getColumnIndexOrThrow(_cursor, "dueDate");
          final int _cursorIndexOfReturnedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "returnedAt");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerComment");
          final int _cursorIndexOfBorrowerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerRating");
          final int _cursorIndexOfBorrowerComment = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerComment");
          final int _cursorIndexOfBookConditionRating = CursorUtil.getColumnIndexOrThrow(_cursor, "bookConditionRating");
          final int _cursorIndexOfIsBorrowerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isBorrowerTxn");
          final int _cursorIndexOfIsOwnerTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isOwnerTxn");
          final int _cursorIndexOfIsHistoryTxn = CursorUtil.getColumnIndexOrThrow(_cursor, "isHistoryTxn");
          final int _cursorIndexOfBorrowerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "borrowerConfirmed");
          final int _cursorIndexOfOwnerConfirmed = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerConfirmed");
          final List<TransactionEntity> _result = new ArrayList<TransactionEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final TransactionEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpBookId;
            _tmpBookId = _cursor.getString(_cursorIndexOfBookId);
            final String _tmpBookTitle;
            _tmpBookTitle = _cursor.getString(_cursorIndexOfBookTitle);
            final String _tmpBookImageUrl;
            if (_cursor.isNull(_cursorIndexOfBookImageUrl)) {
              _tmpBookImageUrl = null;
            } else {
              _tmpBookImageUrl = _cursor.getString(_cursorIndexOfBookImageUrl);
            }
            final String _tmpBorrowerId;
            _tmpBorrowerId = _cursor.getString(_cursorIndexOfBorrowerId);
            final String _tmpBorrowerName;
            _tmpBorrowerName = _cursor.getString(_cursorIndexOfBorrowerName);
            final String _tmpBorrowerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfBorrowerProfileImageUrl)) {
              _tmpBorrowerProfileImageUrl = null;
            } else {
              _tmpBorrowerProfileImageUrl = _cursor.getString(_cursorIndexOfBorrowerProfileImageUrl);
            }
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final String _tmpGroupId;
            _tmpGroupId = _cursor.getString(_cursorIndexOfGroupId);
            final TransactionStatus _tmpStatus;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfStatus);
            _tmpStatus = __converters.fromTransactionStatus(_tmp);
            final BorrowDuration _tmpDuration;
            final String _tmp_1;
            _tmp_1 = _cursor.getString(_cursorIndexOfDuration);
            _tmpDuration = __converters.fromBorrowDuration(_tmp_1);
            final int _tmpDurationDays;
            _tmpDurationDays = _cursor.getInt(_cursorIndexOfDurationDays);
            final double _tmpLendingFee;
            _tmpLendingFee = _cursor.getDouble(_cursorIndexOfLendingFee);
            final String _tmpRequestMessage;
            if (_cursor.isNull(_cursorIndexOfRequestMessage)) {
              _tmpRequestMessage = null;
            } else {
              _tmpRequestMessage = _cursor.getString(_cursorIndexOfRequestMessage);
            }
            final String _tmpRejectionReason;
            if (_cursor.isNull(_cursorIndexOfRejectionReason)) {
              _tmpRejectionReason = null;
            } else {
              _tmpRejectionReason = _cursor.getString(_cursorIndexOfRejectionReason);
            }
            final String _tmpHandoverOTP;
            if (_cursor.isNull(_cursorIndexOfHandoverOTP)) {
              _tmpHandoverOTP = null;
            } else {
              _tmpHandoverOTP = _cursor.getString(_cursorIndexOfHandoverOTP);
            }
            final Date _tmpHandoverOTPExpiry;
            final Long _tmp_2;
            if (_cursor.isNull(_cursorIndexOfHandoverOTPExpiry)) {
              _tmp_2 = null;
            } else {
              _tmp_2 = _cursor.getLong(_cursorIndexOfHandoverOTPExpiry);
            }
            _tmpHandoverOTPExpiry = __converters.fromTimestamp(_tmp_2);
            final String _tmpReturnOTP;
            if (_cursor.isNull(_cursorIndexOfReturnOTP)) {
              _tmpReturnOTP = null;
            } else {
              _tmpReturnOTP = _cursor.getString(_cursorIndexOfReturnOTP);
            }
            final Date _tmpReturnOTPExpiry;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfReturnOTPExpiry)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfReturnOTPExpiry);
            }
            _tmpReturnOTPExpiry = __converters.fromTimestamp(_tmp_3);
            final Date _tmpRequestedAt;
            final Long _tmp_4;
            if (_cursor.isNull(_cursorIndexOfRequestedAt)) {
              _tmp_4 = null;
            } else {
              _tmp_4 = _cursor.getLong(_cursorIndexOfRequestedAt);
            }
            final Date _tmp_5 = __converters.fromTimestamp(_tmp_4);
            if (_tmp_5 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpRequestedAt = _tmp_5;
            }
            final Date _tmpApprovedAt;
            final Long _tmp_6;
            if (_cursor.isNull(_cursorIndexOfApprovedAt)) {
              _tmp_6 = null;
            } else {
              _tmp_6 = _cursor.getLong(_cursorIndexOfApprovedAt);
            }
            _tmpApprovedAt = __converters.fromTimestamp(_tmp_6);
            final Date _tmpHandoverAt;
            final Long _tmp_7;
            if (_cursor.isNull(_cursorIndexOfHandoverAt)) {
              _tmp_7 = null;
            } else {
              _tmp_7 = _cursor.getLong(_cursorIndexOfHandoverAt);
            }
            _tmpHandoverAt = __converters.fromTimestamp(_tmp_7);
            final Date _tmpDueDate;
            final Long _tmp_8;
            if (_cursor.isNull(_cursorIndexOfDueDate)) {
              _tmp_8 = null;
            } else {
              _tmp_8 = _cursor.getLong(_cursorIndexOfDueDate);
            }
            _tmpDueDate = __converters.fromTimestamp(_tmp_8);
            final Date _tmpReturnedAt;
            final Long _tmp_9;
            if (_cursor.isNull(_cursorIndexOfReturnedAt)) {
              _tmp_9 = null;
            } else {
              _tmp_9 = _cursor.getLong(_cursorIndexOfReturnedAt);
            }
            _tmpReturnedAt = __converters.fromTimestamp(_tmp_9);
            final Integer _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getInt(_cursorIndexOfOwnerRating);
            }
            final String _tmpOwnerComment;
            if (_cursor.isNull(_cursorIndexOfOwnerComment)) {
              _tmpOwnerComment = null;
            } else {
              _tmpOwnerComment = _cursor.getString(_cursorIndexOfOwnerComment);
            }
            final Integer _tmpBorrowerRating;
            if (_cursor.isNull(_cursorIndexOfBorrowerRating)) {
              _tmpBorrowerRating = null;
            } else {
              _tmpBorrowerRating = _cursor.getInt(_cursorIndexOfBorrowerRating);
            }
            final String _tmpBorrowerComment;
            if (_cursor.isNull(_cursorIndexOfBorrowerComment)) {
              _tmpBorrowerComment = null;
            } else {
              _tmpBorrowerComment = _cursor.getString(_cursorIndexOfBorrowerComment);
            }
            final Integer _tmpBookConditionRating;
            if (_cursor.isNull(_cursorIndexOfBookConditionRating)) {
              _tmpBookConditionRating = null;
            } else {
              _tmpBookConditionRating = _cursor.getInt(_cursorIndexOfBookConditionRating);
            }
            final boolean _tmpIsBorrowerTxn;
            final int _tmp_10;
            _tmp_10 = _cursor.getInt(_cursorIndexOfIsBorrowerTxn);
            _tmpIsBorrowerTxn = _tmp_10 != 0;
            final boolean _tmpIsOwnerTxn;
            final int _tmp_11;
            _tmp_11 = _cursor.getInt(_cursorIndexOfIsOwnerTxn);
            _tmpIsOwnerTxn = _tmp_11 != 0;
            final boolean _tmpIsHistoryTxn;
            final int _tmp_12;
            _tmp_12 = _cursor.getInt(_cursorIndexOfIsHistoryTxn);
            _tmpIsHistoryTxn = _tmp_12 != 0;
            final PaymentStatusEntity _tmpPaymentStatus;
            final boolean _tmpBorrowerConfirmed;
            final int _tmp_13;
            _tmp_13 = _cursor.getInt(_cursorIndexOfBorrowerConfirmed);
            _tmpBorrowerConfirmed = _tmp_13 != 0;
            final boolean _tmpOwnerConfirmed;
            final int _tmp_14;
            _tmp_14 = _cursor.getInt(_cursorIndexOfOwnerConfirmed);
            _tmpOwnerConfirmed = _tmp_14 != 0;
            _tmpPaymentStatus = new PaymentStatusEntity(_tmpBorrowerConfirmed,_tmpOwnerConfirmed);
            _item = new TransactionEntity(_tmpId,_tmpBookId,_tmpBookTitle,_tmpBookImageUrl,_tmpBorrowerId,_tmpBorrowerName,_tmpBorrowerProfileImageUrl,_tmpOwnerId,_tmpOwnerName,_tmpOwnerProfileImageUrl,_tmpGroupId,_tmpStatus,_tmpDuration,_tmpDurationDays,_tmpLendingFee,_tmpRequestMessage,_tmpRejectionReason,_tmpHandoverOTP,_tmpHandoverOTPExpiry,_tmpReturnOTP,_tmpReturnOTPExpiry,_tmpPaymentStatus,_tmpRequestedAt,_tmpApprovedAt,_tmpHandoverAt,_tmpDueDate,_tmpReturnedAt,_tmpOwnerRating,_tmpOwnerComment,_tmpBorrowerRating,_tmpBorrowerComment,_tmpBookConditionRating,_tmpIsBorrowerTxn,_tmpIsOwnerTxn,_tmpIsHistoryTxn);
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

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
