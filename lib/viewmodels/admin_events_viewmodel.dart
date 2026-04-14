import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:flutter/material.dart';

class AdminEventsViewModel extends ChangeNotifier with FilterableViewModelMixin {
  List<EventModel> filterEvents(List<EventModel> events) {
    return events.where((event) {
      return isDateInFilter(event.dateTime);
    }).toList();
  }
}
