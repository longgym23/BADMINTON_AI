import 'package:badminton_ai/core/cqrs/command_bus.dart';
import 'package:badminton_ai/core/cqrs/query_bus.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/booking/application/commands/add_balance_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/cancel_booking_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/cancel_booking_with_refund_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_booking_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_event_payment_placeholder_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/deduct_balance_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/join_event_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/mark_bookings_paid_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/release_booking_transaction_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/reserve_booking_slots_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/submit_court_review_command.dart';
import 'package:badminton_ai/modules/booking/application/handlers/add_balance_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/cancel_booking_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/cancel_booking_with_refund_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/create_booking_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/create_event_payment_placeholder_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/deduct_balance_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/join_event_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/mark_bookings_paid_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/release_booking_transaction_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/reserve_booking_slots_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/handlers/submit_court_review_command_handler.dart';
import 'package:badminton_ai/modules/booking/application/mediator/booking_module_mediator.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';
import 'package:badminton_ai/modules/booking/infrastructure/repositories/supabase_booking_repository_impl.dart';
import 'package:flutter/foundation.dart';

/// Composition root for the Booking module (vet45-style Startup).
class BookingStartup {
  BookingStartup._({
    required this.bookingRepository,
    required this.bookingModule,
    required this.commandBus,
    required this.queryBus,
  });

  final IBookingRepository bookingRepository;
  final IBookingModule bookingModule;
  final CommandBus commandBus;
  final QueryBus queryBus;

  static BookingStartup? _instance;

  /// Idempotent — safe to call from widget `build` without recreating buses.
  static BookingStartup initialize({
    required SupabaseRepository supabaseRepository,
  }) {
    if (_instance != null) return _instance!;

    final bookingRepository = SupabaseBookingRepositoryImpl(
      repository: supabaseRepository,
    );
    final commandBus = CommandBus();
    final queryBus = QueryBus();

    commandBus.registerHandler<CreateBookingCommand, String>(
      CreateBookingCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<ReserveBookingSlotsCommand, Map<String, dynamic>>(
      ReserveBookingSlotsCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<ReleaseBookingTransactionCommand, int>(
      ReleaseBookingTransactionCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<MarkBookingsPaidCommand, void>(
      MarkBookingsPaidCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<CancelBookingCommand, void>(
      CancelBookingCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<CancelBookingWithRefundCommand, void>(
      CancelBookingWithRefundCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<DeductBalanceCommand, void>(
      DeductBalanceCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<AddBalanceCommand, void>(
      AddBalanceCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<JoinEventCommand, void>(
      JoinEventCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<CreateEventPaymentPlaceholderCommand, void>(
      CreateEventPaymentPlaceholderCommandHandler(bookingRepository: bookingRepository),
    );
    commandBus.registerHandler<SubmitCourtReviewCommand, void>(
      SubmitCourtReviewCommandHandler(bookingRepository: bookingRepository),
    );

    final bookingModule = BookingModuleMediator(
      commandBus: commandBus,
      queryBus: queryBus,
    );

    return _instance = BookingStartup._(
      bookingRepository: bookingRepository,
      bookingModule: bookingModule,
      commandBus: commandBus,
      queryBus: queryBus,
    );
  }

  @visibleForTesting
  static void resetForTest() => _instance = null;
}
