import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/models/review_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review.reviewer;
    final displayName = reviewer?.displayName ?? review.reviewerName ?? 'Người dùng';
    final avatarUrl = reviewer?.photoUrl ?? review.reviewerAvatar;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';
    final dateStr = DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal());

    return VCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: VColors.brandPrimaryLight,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: VTypography.headingSm),
                    Text(dateStr, style: VTypography.bodySm),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            VGap.xs,
            Text(review.comment!, style: VTypography.bodyMd),
          ],
        ],
      ),
    );
  }
}

Widget buildRatingSummary(CourtLocationModel court, List<ReviewModel> reviews) {
  final avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;
  final counts = List.generate(5, (i) => reviews.where((r) => r.rating == 5 - i).length);

  return Column(
    children: [
      Row(
        children: [
          Column(
            children: [
              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: VColors.textPrimary)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.floor() ? Icons.star_rounded : (i < avg ? Icons.star_half_rounded : Icons.star_border_rounded),
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${reviews.length} đánh giá', style: VTypography.bodySm),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[i];
                final ratio = reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: VTypography.bodySm),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: VColors.borderDefault,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(width: 20, child: Text('$count', style: VTypography.bodySm)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      const Divider(height: 24),
    ],
  );
}

void showReviewBottomSheet(BuildContext context, CourtLocationModel court, String userId, VoidCallback onSubmitted) {
  int selectedRating = 5;
  final commentController = TextEditingController();
  bool submitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Viết đánh giá', style: VTypography.headingMd)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Text(court.name, style: VTypography.bodySm),
                const SizedBox(height: 20),
                const Text('Chất lượng sân', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 40),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ trải nghiệm của bạn...',
                    filled: true,
                    fillColor: VColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: submitting ? null : () async {
                      setModalState(() => submitting = true);
                      try {
                        final review = ReviewModel(
                          id: '',
                          courtId: court.id,
                          userId: userId,
                          rating: selectedRating,
                          comment: commentController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await SupabaseRepository().submitReview(review);
                        if (ctx.mounted) Navigator.pop(ctx);
                        onSubmitted();
                      } catch (e) {
                        if (ctx.mounted) AppToast.show(ctx, 'Lỗi: $e', type: ToastType.error);
                        setModalState(() => submitting = false);
                      }
                    },
                    child: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
