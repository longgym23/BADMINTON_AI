import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/modules/profile/viewmodels/favorite_courts_provider.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/court_selection_screen.dart';
import 'package:badminton_ai/modules/map/views/pages/court_detail_sheet.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          'profile_screen.favoriteCourts'.tr(),
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_rounded, color: Colors.red),
            onPressed: null,
            tooltip: 'screens.favoritesList'.tr(),
          ),
        ],
      ),
      body: Consumer<FavoriteCourtsProvider>(
        builder: (context, fav, _) {
          final courts = fav.favorites;

          if (courts.isEmpty) {
            return _EmptyFavorites();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              return Dismissible(
                key: ValueKey(court.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  margin: EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Image(
                    image: AssetImage('assets/images/delete.png'),
                    color: Colors.red,
                    height: 28,
                    width: 28,
                  ),
                ),
                onDismissed: (_) => fav.removeFavorite(court.id),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CourtDetailSheet(court: court),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child:
                                court.imageUrl != null &&
                                    court.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: court.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _CourtImagePlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _CourtImagePlaceholder(),
                                  )
                                : _CourtImagePlaceholder(),
                          ),
                        ),

                        // Info
                        Padding(
                          padding: EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + Rating
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      court.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: VColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        court.rating > 0
                                            ? court.rating.toStringAsFixed(1)
                                            : '—',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),

                              // Sport chip
                              _SportChip(sportType: court.sportType),
                              SizedBox(height: 8),

                              // Address
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      court.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: VColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),

                              // Price
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    color: VColors.brandPrimary,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${court.pricePerHour.toStringAsFixed(0)}đ/giờ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: VColors.brandPrimaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Action buttons
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        fav.removeFavorite(court.id),
                                    icon: Icon(
                                      Icons.favorite_border_rounded,
                                      size: 16,
                                    ),
                                    label: Text('screens.unsave'.tr()),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CourtSelectionScreen(
                                                  selectedCourt: court,
                                                  selectedDate: DateTime.now(),
                                                ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.sports_tennis_rounded,
                                        size: 16,
                                      ),
                                      label: Text('screens.setThePitch1'.tr()),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'screens.noFavoriteCourseYet'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'screens.pressWhenViewingCourseDe'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.brandPrimarySubdued,
      child: Center(
        child: Icon(
          Icons.sports_rounded,
          size: 48,
          color: VColors.brandPrimary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  final String? sportType;
  const _SportChip({this.sportType});

  String get _label {
    switch (sportType?.toLowerCase()) {
      case 'pickleball':
        return 'Pickleball';
      case 'football':
        return 'screens.football'.tr();
      case 'tennis':
        return 'Tennis';
      default:
        return 'screens.badminton'.tr();
    }
  }

  Color get _color {
    switch (sportType?.toLowerCase()) {
      case 'pickleball':
        return Colors.blue;
      case 'football':
        return Colors.orange;
      case 'tennis':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

