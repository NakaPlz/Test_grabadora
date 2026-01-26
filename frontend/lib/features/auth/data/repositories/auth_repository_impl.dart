import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login(String email, String password) async {
    // 1. Get Token
    await remoteDataSource.login(email, password);
    // 2. In a real app, we might fetch user profile here using the token.
    // For MVP, we'll return a dummy user object or decode the token if it had user info.
    // Let's return a basic user for now since /auth/token only returns the token.
    return User(id: 0, email: email, isActive: true); 
  }

  @override
  Future<User> signUp(String email, String password) async {
    return await remoteDataSource.signUp(email, password);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<String?> getToken() async {
    return await remoteDataSource.getToken();
  }
}
