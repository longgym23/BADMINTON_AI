import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/review_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CourtReviewsScreen extends StatefulWidget {
  final CourtLocationModel court;

  const CourtReviewsScreen({super.key, required this.court});

  @override
  State<CourtReviewsScreen> createState() => _CourtReviewsScreenState();
}

class _CourtReviewsScreenState extends State<CourtReviewsScreen> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final repo = context.read<SupabaseRepository>();
      final reviews = await repo.getReviewsForCourt(widget.court.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomGradientAppBar(
        title: Text(
          'Đánh giá ${widget.court.name}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reviews.isEmpty
              ? _buildEmptyState()
              : _buildReviewsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text('screens.thereAreNoReviewsYet'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          SizedBox(height: 8),
          Text('screens.beTheFirstToLeaveAReview'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    // Calculate stats
    final averageRating = _reviews.isEmpty
        ? 0.0
        : _reviews.fold(0, (sum, item) => sum + item.rating) / _reviews.length;
    
    return Column(
      children: [
        // Top summary
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                   Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dựa trên ${_reviews.length} đánh giá',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: AppColors.borderColor),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _ReviewCard(review: review);
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review.reviewer;
    final initials = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'screens.user'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy', 'vi_VN').format(review.createdAt),
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                color: AppColors.textBlack,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

