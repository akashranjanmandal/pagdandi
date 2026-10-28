import 'package:core_model/core_model.dart';
import 'package:drift/drift.dart';

/// The SMS outbox: written before any SOS is sent.
@DataClassName('OutboxRow')
class SmsOutbox extends Table {
  @override
  String get tableName => 'sms_outbox';

  /// Unique id (one per contact per SOS).
  TextColumn get id => text()();

  /// Destination number.
  TextColumn get recipient => text()();

  /// Message text.
  TextColumn get body => text()();

  /// Purpose.
  TextColumn get kind => textEnum<OutboxKind>()();

  /// Life-cycle status.
  TextColumn get status => textEnum<SmsStatus>()();

  /// Times handed to the radio.
  IntColumn get attempts => integer()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime()();

  /// Earliest next attempt.
  DateTimeColumn get nextAttemptAt => dateTime()();

  /// Last attempt, if any.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Written ONLY by the native safety guard: its view of the message
  /// (sending, sent, delivered, failed), or null if it never touched it.
  TextColumn get guardStatus => text().nullable()();

  /// Written ONLY by the native safety guard: its send attempts.
  IntColumn get guardAttempts => integer().withDefault(const Constant(0))();

  /// Written ONLY by the native safety guard: when it last updated the row.
  DateTimeColumn get guardUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Trek state snapshots, persisted on every transition.
@DataClassName('SnapshotRow')
class StateSnapshots extends Table {
  @override
  String get tableName => 'state_snapshots';

  /// Auto id.
  IntColumn get id => integer().autoIncrement()();

  /// When the snapshot was taken.
  DateTimeColumn get takenAt => dateTime()();

  /// Snapshot format version.
  IntColumn get version => integer()();

  /// The snapshot as JSON.
  TextColumn get json => text()();
}

/// Bounded log of events for diagnostics.
@DataClassName('EventRow')
class EventLog extends Table {
  @override
  String get tableName => 'event_log';

  /// Auto id.
  IntColumn get id => integer().autoIncrement()();

  /// When it happened.
  DateTimeColumn get at => dateTime()();

  /// Event type name.
  TextColumn get type => text()();

  /// Short detail.
  TextColumn get detail => text()();
}

/// A trek.
@DataClassName('TripRow')
class Trips extends Table {
  /// Auto id.
  IntColumn get id => integer().autoIncrement()();

  /// Name.
  TextColumn get name => text()();

  /// Start.
  DateTimeColumn get startedAt => dateTime()();

  /// End, null while the trek is running.
  DateTimeColumn get endedAt => dateTime().nullable()();
}

/// Breadcrumb: accepted GPS fixes of a trek.
@DataClassName('TrackPointRow')
class TrackPoints extends Table {
  @override
  String get tableName => 'track_points';

  /// Auto id.
  IntColumn get id => integer().autoIncrement()();

  /// Owning trip.
  IntColumn get tripId => integer().references(Trips, #id)();

  /// GPS time.
  DateTimeColumn get at => dateTime()();

  /// Degrees north.
  RealColumn get latitude => real()();

  /// Degrees east.
  RealColumn get longitude => real()();

  /// Accuracy radius in metres.
  RealColumn get accuracyM => real()();

  /// Altitude in metres, if known.
  RealColumn get altitudeM => real().nullable()();
}

/// Key-value settings.
@DataClassName('SettingRow')
class Settings extends Table {
  /// Key.
  TextColumn get key => text()();

  /// Value.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// A marker the walker dropped (a camp, a hazard, a water source).
@DataClassName('PinRow')
class Pins extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// When it was dropped (trusted time).
  DateTimeColumn get at => dateTime()();

  /// Degrees north.
  RealColumn get lat => real()();

  /// Degrees east.
  RealColumn get lon => real()();

  /// Accuracy radius in metres, if known.
  RealColumn get accuracyM => real().nullable()();

  /// Short name ("Pin 3").
  TextColumn get label => text()();
}
