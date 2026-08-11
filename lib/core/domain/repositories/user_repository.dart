import 'package:badminton_ai/domain/entities/user.dart';

abstract class UserRepository {
  Stream<List<User>> getUsersStream();
  
  Future<User?> getUserById(String userId);
  
  Future<void> updateUser(User user);
  
  Future<void> deleteUser(String userId);
  
  Future<void> updateUserRole(String userId, UserRole role);
}