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
import com.bookstore.bookapp.data.local.entity.BookEntity;
import com.bookstore.bookapp.domain.model.BookCondition;
import java.lang.Class;
import java.lang.Double;
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
public final class BookDao_Impl implements BookDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<BookEntity> __insertionAdapterOfBookEntity;

  private final Converters __converters = new Converters();

  private final SharedSQLiteStatement __preparedStmtOfClearMyBooks;

  private final SharedSQLiteStatement __preparedStmtOfClearAll;

  public BookDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfBookEntity = new EntityInsertionAdapter<BookEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `books` (`id`,`title`,`author`,`genre`,`description`,`personalNotes`,`imageUrl`,`isbn`,`publisher`,`year`,`pages`,`language`,`condition`,`lendingPricePerWeek`,`isAvailable`,`ownerId`,`ownerName`,`ownerRating`,`ownerBooksCount`,`ownerProfileImageUrl`,`visibleInGroups`,`currentTransactionId`,`createdAt`,`updatedAt`,`isMyBook`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final BookEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getAuthor());
        statement.bindString(4, entity.getGenre());
        statement.bindString(5, entity.getDescription());
        if (entity.getPersonalNotes() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getPersonalNotes());
        }
        statement.bindString(7, entity.getImageUrl());
        if (entity.getIsbn() == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, entity.getIsbn());
        }
        if (entity.getPublisher() == null) {
          statement.bindNull(9);
        } else {
          statement.bindString(9, entity.getPublisher());
        }
        if (entity.getYear() == null) {
          statement.bindNull(10);
        } else {
          statement.bindLong(10, entity.getYear());
        }
        if (entity.getPages() == null) {
          statement.bindNull(11);
        } else {
          statement.bindLong(11, entity.getPages());
        }
        if (entity.getLanguage() == null) {
          statement.bindNull(12);
        } else {
          statement.bindString(12, entity.getLanguage());
        }
        final String _tmp = __converters.toBookCondition(entity.getCondition());
        statement.bindString(13, _tmp);
        statement.bindDouble(14, entity.getLendingPricePerWeek());
        final int _tmp_1 = entity.isAvailable() ? 1 : 0;
        statement.bindLong(15, _tmp_1);
        statement.bindString(16, entity.getOwnerId());
        statement.bindString(17, entity.getOwnerName());
        if (entity.getOwnerRating() == null) {
          statement.bindNull(18);
        } else {
          statement.bindDouble(18, entity.getOwnerRating());
        }
        if (entity.getOwnerBooksCount() == null) {
          statement.bindNull(19);
        } else {
          statement.bindLong(19, entity.getOwnerBooksCount());
        }
        if (entity.getOwnerProfileImageUrl() == null) {
          statement.bindNull(20);
        } else {
          statement.bindString(20, entity.getOwnerProfileImageUrl());
        }
        final String _tmp_2 = __converters.toStringList(entity.getVisibleInGroups());
        statement.bindString(21, _tmp_2);
        if (entity.getCurrentTransactionId() == null) {
          statement.bindNull(22);
        } else {
          statement.bindString(22, entity.getCurrentTransactionId());
        }
        final Long _tmp_3 = __converters.dateToTimestamp(entity.getCreatedAt());
        if (_tmp_3 == null) {
          statement.bindNull(23);
        } else {
          statement.bindLong(23, _tmp_3);
        }
        final Long _tmp_4 = __converters.dateToTimestamp(entity.getUpdatedAt());
        if (_tmp_4 == null) {
          statement.bindNull(24);
        } else {
          statement.bindLong(24, _tmp_4);
        }
        final int _tmp_5 = entity.isMyBook() ? 1 : 0;
        statement.bindLong(25, _tmp_5);
      }
    };
    this.__preparedStmtOfClearMyBooks = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM books WHERE isMyBook = 1";
        return _query;
      }
    };
    this.__preparedStmtOfClearAll = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM books";
        return _query;
      }
    };
  }

  @Override
  public Object insertBooks(final List<BookEntity> books,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfBookEntity.insert(books);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object insertBook(final BookEntity book, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfBookEntity.insert(book);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object clearMyBooks(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfClearMyBooks.acquire();
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
          __preparedStmtOfClearMyBooks.release(_stmt);
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
  public Flow<List<BookEntity>> getAllBooks() {
    final String _sql = "SELECT * FROM books";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"books"}, new Callable<List<BookEntity>>() {
      @Override
      @NonNull
      public List<BookEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfAuthor = CursorUtil.getColumnIndexOrThrow(_cursor, "author");
          final int _cursorIndexOfGenre = CursorUtil.getColumnIndexOrThrow(_cursor, "genre");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfPersonalNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "personalNotes");
          final int _cursorIndexOfImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "imageUrl");
          final int _cursorIndexOfIsbn = CursorUtil.getColumnIndexOrThrow(_cursor, "isbn");
          final int _cursorIndexOfPublisher = CursorUtil.getColumnIndexOrThrow(_cursor, "publisher");
          final int _cursorIndexOfYear = CursorUtil.getColumnIndexOrThrow(_cursor, "year");
          final int _cursorIndexOfPages = CursorUtil.getColumnIndexOrThrow(_cursor, "pages");
          final int _cursorIndexOfLanguage = CursorUtil.getColumnIndexOrThrow(_cursor, "language");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfLendingPricePerWeek = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingPricePerWeek");
          final int _cursorIndexOfIsAvailable = CursorUtil.getColumnIndexOrThrow(_cursor, "isAvailable");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerBooksCount");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfVisibleInGroups = CursorUtil.getColumnIndexOrThrow(_cursor, "visibleInGroups");
          final int _cursorIndexOfCurrentTransactionId = CursorUtil.getColumnIndexOrThrow(_cursor, "currentTransactionId");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyBook = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyBook");
          final List<BookEntity> _result = new ArrayList<BookEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final BookEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpAuthor;
            _tmpAuthor = _cursor.getString(_cursorIndexOfAuthor);
            final String _tmpGenre;
            _tmpGenre = _cursor.getString(_cursorIndexOfGenre);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpPersonalNotes;
            if (_cursor.isNull(_cursorIndexOfPersonalNotes)) {
              _tmpPersonalNotes = null;
            } else {
              _tmpPersonalNotes = _cursor.getString(_cursorIndexOfPersonalNotes);
            }
            final String _tmpImageUrl;
            _tmpImageUrl = _cursor.getString(_cursorIndexOfImageUrl);
            final String _tmpIsbn;
            if (_cursor.isNull(_cursorIndexOfIsbn)) {
              _tmpIsbn = null;
            } else {
              _tmpIsbn = _cursor.getString(_cursorIndexOfIsbn);
            }
            final String _tmpPublisher;
            if (_cursor.isNull(_cursorIndexOfPublisher)) {
              _tmpPublisher = null;
            } else {
              _tmpPublisher = _cursor.getString(_cursorIndexOfPublisher);
            }
            final Integer _tmpYear;
            if (_cursor.isNull(_cursorIndexOfYear)) {
              _tmpYear = null;
            } else {
              _tmpYear = _cursor.getInt(_cursorIndexOfYear);
            }
            final Integer _tmpPages;
            if (_cursor.isNull(_cursorIndexOfPages)) {
              _tmpPages = null;
            } else {
              _tmpPages = _cursor.getInt(_cursorIndexOfPages);
            }
            final String _tmpLanguage;
            if (_cursor.isNull(_cursorIndexOfLanguage)) {
              _tmpLanguage = null;
            } else {
              _tmpLanguage = _cursor.getString(_cursorIndexOfLanguage);
            }
            final BookCondition _tmpCondition;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCondition);
            _tmpCondition = __converters.fromBookCondition(_tmp);
            final double _tmpLendingPricePerWeek;
            _tmpLendingPricePerWeek = _cursor.getDouble(_cursorIndexOfLendingPricePerWeek);
            final boolean _tmpIsAvailable;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsAvailable);
            _tmpIsAvailable = _tmp_1 != 0;
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final Double _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getDouble(_cursorIndexOfOwnerRating);
            }
            final Integer _tmpOwnerBooksCount;
            if (_cursor.isNull(_cursorIndexOfOwnerBooksCount)) {
              _tmpOwnerBooksCount = null;
            } else {
              _tmpOwnerBooksCount = _cursor.getInt(_cursorIndexOfOwnerBooksCount);
            }
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final List<String> _tmpVisibleInGroups;
            final String _tmp_2;
            _tmp_2 = _cursor.getString(_cursorIndexOfVisibleInGroups);
            _tmpVisibleInGroups = __converters.fromStringList(_tmp_2);
            final String _tmpCurrentTransactionId;
            if (_cursor.isNull(_cursorIndexOfCurrentTransactionId)) {
              _tmpCurrentTransactionId = null;
            } else {
              _tmpCurrentTransactionId = _cursor.getString(_cursorIndexOfCurrentTransactionId);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_4 = __converters.fromTimestamp(_tmp_3);
            if (_tmp_4 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_4;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_5);
            final boolean _tmpIsMyBook;
            final int _tmp_6;
            _tmp_6 = _cursor.getInt(_cursorIndexOfIsMyBook);
            _tmpIsMyBook = _tmp_6 != 0;
            _item = new BookEntity(_tmpId,_tmpTitle,_tmpAuthor,_tmpGenre,_tmpDescription,_tmpPersonalNotes,_tmpImageUrl,_tmpIsbn,_tmpPublisher,_tmpYear,_tmpPages,_tmpLanguage,_tmpCondition,_tmpLendingPricePerWeek,_tmpIsAvailable,_tmpOwnerId,_tmpOwnerName,_tmpOwnerRating,_tmpOwnerBooksCount,_tmpOwnerProfileImageUrl,_tmpVisibleInGroups,_tmpCurrentTransactionId,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyBook);
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
  public Flow<List<BookEntity>> getMyBooks() {
    final String _sql = "SELECT * FROM books WHERE isMyBook = 1";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"books"}, new Callable<List<BookEntity>>() {
      @Override
      @NonNull
      public List<BookEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfAuthor = CursorUtil.getColumnIndexOrThrow(_cursor, "author");
          final int _cursorIndexOfGenre = CursorUtil.getColumnIndexOrThrow(_cursor, "genre");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfPersonalNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "personalNotes");
          final int _cursorIndexOfImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "imageUrl");
          final int _cursorIndexOfIsbn = CursorUtil.getColumnIndexOrThrow(_cursor, "isbn");
          final int _cursorIndexOfPublisher = CursorUtil.getColumnIndexOrThrow(_cursor, "publisher");
          final int _cursorIndexOfYear = CursorUtil.getColumnIndexOrThrow(_cursor, "year");
          final int _cursorIndexOfPages = CursorUtil.getColumnIndexOrThrow(_cursor, "pages");
          final int _cursorIndexOfLanguage = CursorUtil.getColumnIndexOrThrow(_cursor, "language");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfLendingPricePerWeek = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingPricePerWeek");
          final int _cursorIndexOfIsAvailable = CursorUtil.getColumnIndexOrThrow(_cursor, "isAvailable");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerBooksCount");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfVisibleInGroups = CursorUtil.getColumnIndexOrThrow(_cursor, "visibleInGroups");
          final int _cursorIndexOfCurrentTransactionId = CursorUtil.getColumnIndexOrThrow(_cursor, "currentTransactionId");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyBook = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyBook");
          final List<BookEntity> _result = new ArrayList<BookEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final BookEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpAuthor;
            _tmpAuthor = _cursor.getString(_cursorIndexOfAuthor);
            final String _tmpGenre;
            _tmpGenre = _cursor.getString(_cursorIndexOfGenre);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpPersonalNotes;
            if (_cursor.isNull(_cursorIndexOfPersonalNotes)) {
              _tmpPersonalNotes = null;
            } else {
              _tmpPersonalNotes = _cursor.getString(_cursorIndexOfPersonalNotes);
            }
            final String _tmpImageUrl;
            _tmpImageUrl = _cursor.getString(_cursorIndexOfImageUrl);
            final String _tmpIsbn;
            if (_cursor.isNull(_cursorIndexOfIsbn)) {
              _tmpIsbn = null;
            } else {
              _tmpIsbn = _cursor.getString(_cursorIndexOfIsbn);
            }
            final String _tmpPublisher;
            if (_cursor.isNull(_cursorIndexOfPublisher)) {
              _tmpPublisher = null;
            } else {
              _tmpPublisher = _cursor.getString(_cursorIndexOfPublisher);
            }
            final Integer _tmpYear;
            if (_cursor.isNull(_cursorIndexOfYear)) {
              _tmpYear = null;
            } else {
              _tmpYear = _cursor.getInt(_cursorIndexOfYear);
            }
            final Integer _tmpPages;
            if (_cursor.isNull(_cursorIndexOfPages)) {
              _tmpPages = null;
            } else {
              _tmpPages = _cursor.getInt(_cursorIndexOfPages);
            }
            final String _tmpLanguage;
            if (_cursor.isNull(_cursorIndexOfLanguage)) {
              _tmpLanguage = null;
            } else {
              _tmpLanguage = _cursor.getString(_cursorIndexOfLanguage);
            }
            final BookCondition _tmpCondition;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCondition);
            _tmpCondition = __converters.fromBookCondition(_tmp);
            final double _tmpLendingPricePerWeek;
            _tmpLendingPricePerWeek = _cursor.getDouble(_cursorIndexOfLendingPricePerWeek);
            final boolean _tmpIsAvailable;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsAvailable);
            _tmpIsAvailable = _tmp_1 != 0;
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final Double _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getDouble(_cursorIndexOfOwnerRating);
            }
            final Integer _tmpOwnerBooksCount;
            if (_cursor.isNull(_cursorIndexOfOwnerBooksCount)) {
              _tmpOwnerBooksCount = null;
            } else {
              _tmpOwnerBooksCount = _cursor.getInt(_cursorIndexOfOwnerBooksCount);
            }
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final List<String> _tmpVisibleInGroups;
            final String _tmp_2;
            _tmp_2 = _cursor.getString(_cursorIndexOfVisibleInGroups);
            _tmpVisibleInGroups = __converters.fromStringList(_tmp_2);
            final String _tmpCurrentTransactionId;
            if (_cursor.isNull(_cursorIndexOfCurrentTransactionId)) {
              _tmpCurrentTransactionId = null;
            } else {
              _tmpCurrentTransactionId = _cursor.getString(_cursorIndexOfCurrentTransactionId);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_4 = __converters.fromTimestamp(_tmp_3);
            if (_tmp_4 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_4;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_5);
            final boolean _tmpIsMyBook;
            final int _tmp_6;
            _tmp_6 = _cursor.getInt(_cursorIndexOfIsMyBook);
            _tmpIsMyBook = _tmp_6 != 0;
            _item = new BookEntity(_tmpId,_tmpTitle,_tmpAuthor,_tmpGenre,_tmpDescription,_tmpPersonalNotes,_tmpImageUrl,_tmpIsbn,_tmpPublisher,_tmpYear,_tmpPages,_tmpLanguage,_tmpCondition,_tmpLendingPricePerWeek,_tmpIsAvailable,_tmpOwnerId,_tmpOwnerName,_tmpOwnerRating,_tmpOwnerBooksCount,_tmpOwnerProfileImageUrl,_tmpVisibleInGroups,_tmpCurrentTransactionId,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyBook);
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
  public Object getBookById(final String id, final Continuation<? super BookEntity> $completion) {
    final String _sql = "SELECT * FROM books WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<BookEntity>() {
      @Override
      @Nullable
      public BookEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfAuthor = CursorUtil.getColumnIndexOrThrow(_cursor, "author");
          final int _cursorIndexOfGenre = CursorUtil.getColumnIndexOrThrow(_cursor, "genre");
          final int _cursorIndexOfDescription = CursorUtil.getColumnIndexOrThrow(_cursor, "description");
          final int _cursorIndexOfPersonalNotes = CursorUtil.getColumnIndexOrThrow(_cursor, "personalNotes");
          final int _cursorIndexOfImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "imageUrl");
          final int _cursorIndexOfIsbn = CursorUtil.getColumnIndexOrThrow(_cursor, "isbn");
          final int _cursorIndexOfPublisher = CursorUtil.getColumnIndexOrThrow(_cursor, "publisher");
          final int _cursorIndexOfYear = CursorUtil.getColumnIndexOrThrow(_cursor, "year");
          final int _cursorIndexOfPages = CursorUtil.getColumnIndexOrThrow(_cursor, "pages");
          final int _cursorIndexOfLanguage = CursorUtil.getColumnIndexOrThrow(_cursor, "language");
          final int _cursorIndexOfCondition = CursorUtil.getColumnIndexOrThrow(_cursor, "condition");
          final int _cursorIndexOfLendingPricePerWeek = CursorUtil.getColumnIndexOrThrow(_cursor, "lendingPricePerWeek");
          final int _cursorIndexOfIsAvailable = CursorUtil.getColumnIndexOrThrow(_cursor, "isAvailable");
          final int _cursorIndexOfOwnerId = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerId");
          final int _cursorIndexOfOwnerName = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerName");
          final int _cursorIndexOfOwnerRating = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerRating");
          final int _cursorIndexOfOwnerBooksCount = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerBooksCount");
          final int _cursorIndexOfOwnerProfileImageUrl = CursorUtil.getColumnIndexOrThrow(_cursor, "ownerProfileImageUrl");
          final int _cursorIndexOfVisibleInGroups = CursorUtil.getColumnIndexOrThrow(_cursor, "visibleInGroups");
          final int _cursorIndexOfCurrentTransactionId = CursorUtil.getColumnIndexOrThrow(_cursor, "currentTransactionId");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updatedAt");
          final int _cursorIndexOfIsMyBook = CursorUtil.getColumnIndexOrThrow(_cursor, "isMyBook");
          final BookEntity _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpAuthor;
            _tmpAuthor = _cursor.getString(_cursorIndexOfAuthor);
            final String _tmpGenre;
            _tmpGenre = _cursor.getString(_cursorIndexOfGenre);
            final String _tmpDescription;
            _tmpDescription = _cursor.getString(_cursorIndexOfDescription);
            final String _tmpPersonalNotes;
            if (_cursor.isNull(_cursorIndexOfPersonalNotes)) {
              _tmpPersonalNotes = null;
            } else {
              _tmpPersonalNotes = _cursor.getString(_cursorIndexOfPersonalNotes);
            }
            final String _tmpImageUrl;
            _tmpImageUrl = _cursor.getString(_cursorIndexOfImageUrl);
            final String _tmpIsbn;
            if (_cursor.isNull(_cursorIndexOfIsbn)) {
              _tmpIsbn = null;
            } else {
              _tmpIsbn = _cursor.getString(_cursorIndexOfIsbn);
            }
            final String _tmpPublisher;
            if (_cursor.isNull(_cursorIndexOfPublisher)) {
              _tmpPublisher = null;
            } else {
              _tmpPublisher = _cursor.getString(_cursorIndexOfPublisher);
            }
            final Integer _tmpYear;
            if (_cursor.isNull(_cursorIndexOfYear)) {
              _tmpYear = null;
            } else {
              _tmpYear = _cursor.getInt(_cursorIndexOfYear);
            }
            final Integer _tmpPages;
            if (_cursor.isNull(_cursorIndexOfPages)) {
              _tmpPages = null;
            } else {
              _tmpPages = _cursor.getInt(_cursorIndexOfPages);
            }
            final String _tmpLanguage;
            if (_cursor.isNull(_cursorIndexOfLanguage)) {
              _tmpLanguage = null;
            } else {
              _tmpLanguage = _cursor.getString(_cursorIndexOfLanguage);
            }
            final BookCondition _tmpCondition;
            final String _tmp;
            _tmp = _cursor.getString(_cursorIndexOfCondition);
            _tmpCondition = __converters.fromBookCondition(_tmp);
            final double _tmpLendingPricePerWeek;
            _tmpLendingPricePerWeek = _cursor.getDouble(_cursorIndexOfLendingPricePerWeek);
            final boolean _tmpIsAvailable;
            final int _tmp_1;
            _tmp_1 = _cursor.getInt(_cursorIndexOfIsAvailable);
            _tmpIsAvailable = _tmp_1 != 0;
            final String _tmpOwnerId;
            _tmpOwnerId = _cursor.getString(_cursorIndexOfOwnerId);
            final String _tmpOwnerName;
            _tmpOwnerName = _cursor.getString(_cursorIndexOfOwnerName);
            final Double _tmpOwnerRating;
            if (_cursor.isNull(_cursorIndexOfOwnerRating)) {
              _tmpOwnerRating = null;
            } else {
              _tmpOwnerRating = _cursor.getDouble(_cursorIndexOfOwnerRating);
            }
            final Integer _tmpOwnerBooksCount;
            if (_cursor.isNull(_cursorIndexOfOwnerBooksCount)) {
              _tmpOwnerBooksCount = null;
            } else {
              _tmpOwnerBooksCount = _cursor.getInt(_cursorIndexOfOwnerBooksCount);
            }
            final String _tmpOwnerProfileImageUrl;
            if (_cursor.isNull(_cursorIndexOfOwnerProfileImageUrl)) {
              _tmpOwnerProfileImageUrl = null;
            } else {
              _tmpOwnerProfileImageUrl = _cursor.getString(_cursorIndexOfOwnerProfileImageUrl);
            }
            final List<String> _tmpVisibleInGroups;
            final String _tmp_2;
            _tmp_2 = _cursor.getString(_cursorIndexOfVisibleInGroups);
            _tmpVisibleInGroups = __converters.fromStringList(_tmp_2);
            final String _tmpCurrentTransactionId;
            if (_cursor.isNull(_cursorIndexOfCurrentTransactionId)) {
              _tmpCurrentTransactionId = null;
            } else {
              _tmpCurrentTransactionId = _cursor.getString(_cursorIndexOfCurrentTransactionId);
            }
            final Date _tmpCreatedAt;
            final Long _tmp_3;
            if (_cursor.isNull(_cursorIndexOfCreatedAt)) {
              _tmp_3 = null;
            } else {
              _tmp_3 = _cursor.getLong(_cursorIndexOfCreatedAt);
            }
            final Date _tmp_4 = __converters.fromTimestamp(_tmp_3);
            if (_tmp_4 == null) {
              throw new IllegalStateException("Expected NON-NULL 'java.util.Date', but it was NULL.");
            } else {
              _tmpCreatedAt = _tmp_4;
            }
            final Date _tmpUpdatedAt;
            final Long _tmp_5;
            if (_cursor.isNull(_cursorIndexOfUpdatedAt)) {
              _tmp_5 = null;
            } else {
              _tmp_5 = _cursor.getLong(_cursorIndexOfUpdatedAt);
            }
            _tmpUpdatedAt = __converters.fromTimestamp(_tmp_5);
            final boolean _tmpIsMyBook;
            final int _tmp_6;
            _tmp_6 = _cursor.getInt(_cursorIndexOfIsMyBook);
            _tmpIsMyBook = _tmp_6 != 0;
            _result = new BookEntity(_tmpId,_tmpTitle,_tmpAuthor,_tmpGenre,_tmpDescription,_tmpPersonalNotes,_tmpImageUrl,_tmpIsbn,_tmpPublisher,_tmpYear,_tmpPages,_tmpLanguage,_tmpCondition,_tmpLendingPricePerWeek,_tmpIsAvailable,_tmpOwnerId,_tmpOwnerName,_tmpOwnerRating,_tmpOwnerBooksCount,_tmpOwnerProfileImageUrl,_tmpVisibleInGroups,_tmpCurrentTransactionId,_tmpCreatedAt,_tmpUpdatedAt,_tmpIsMyBook);
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
