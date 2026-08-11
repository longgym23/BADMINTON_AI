import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/data/models/user_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/utils/dialog_utils.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';

class WalletDialogUtils {
  static void showAdjustBalanceDialog(
    BuildContext context,
    UserModel user,
    VoidCallback onSuccess,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    bool isAdd = true;

    DialogUtils.showCustomDialog(
      context,
      title: 'Điều chỉnh số dư ví',
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. User Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.blueGrey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user.displayName ?? user.email ?? 'Khách hàng',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Số dư hiện tại: ',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              Text(
                                NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(user.balance),
                                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Action Switcher (Cộng / Trừ)
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() => isAdd = true);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isAdd ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isAdd ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                ),
                                margin: const EdgeInsets.all(2),
                                alignment: Alignment.center,
                                child: Text(
                                  'Cộng tiền (+)',
                                  style: TextStyle(
                                    color: isAdd ? Colors.green[700] : Colors.grey[600],
                                    fontWeight: isAdd ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() => isAdd = false);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !isAdd ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: !isAdd ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                                ),
                                margin: const EdgeInsets.all(2),
                                alignment: Alignment.center,
                                child: Text(
                                  'Trừ tiền (-)',
                                  style: TextStyle(
                                    color: !isAdd ? Colors.red[700] : Colors.grey[600],
                                    fontWeight: !isAdd ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Amount Input
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VColors.brandPrimaryDark),
                      decoration: InputDecoration(
                        labelText: 'Số tiền (VNĐ)',
                        labelStyle: const TextStyle(fontSize: 14),
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Icon(Icons.attach_money, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VColors.brandPrimary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {}); // Re-render to show preview
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                        final amount = int.tryParse(value);
                        if (amount == null || amount <= 0) return 'Số tiền không hợp lệ';
                        if (!isAdd && amount > user.balance) return 'Số tiền trừ không được vượt quá số dư';
                        return null;
                      },
                    ),

                    // 4. Quick Amount Chips
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [50000, 100000, 200000, 500000].map((amount) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                amountController.text = amount.toString();
                                setDialogState(() {});
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: VColors.brandPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: VColors.brandPrimary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '+${(amount / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    color: VColors.brandPrimaryDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 5. New Balance Preview
                    if (amountController.text.isNotEmpty && int.tryParse(amountController.text) != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isAdd ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isAdd ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số dư mới sẽ là:',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            Text(
                              NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(
                                  user.balance + (isAdd ? int.parse(amountController.text) : -int.parse(amountController.text))),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isAdd ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                final repo = context.read<SupabaseRepository>();
                final amount = int.parse(amountController.text.trim());
                
                if (isAdd) {
                  await repo.addBalance(user.id, amount);
                } else {
                  await repo.deductBalance(user.id, amount);
                }
                
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(
                  context,
                  'Cập nhật số dư thành công!',
                  type: ToastType.success,
                );
                onSuccess(); // Re-render parent list
              } catch (e) {
                AppToast.show(
                  context,
                  'Lỗi cập nhật số dư: $e',
                  type: ToastType.error,
                );
              }
            }
          },
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}
