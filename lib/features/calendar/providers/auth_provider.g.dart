// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends $NotifierProvider<AuthState, GoogleSignInAccount?> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  AuthState create() => AuthState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignInAccount? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignInAccount?>(value),
    );
  }
}

String _$authStateHash() => r'1b75287008fa470a8e81281dc164198d3c6b5193';

abstract class _$AuthState extends $Notifier<GoogleSignInAccount?> {
  GoogleSignInAccount? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GoogleSignInAccount?, GoogleSignInAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoogleSignInAccount?, GoogleSignInAccount?>,
              GoogleSignInAccount?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          GoogleSignInAccount?,
          GoogleSignInAccount?,
          GoogleSignInAccount?
        >
    with $Provider<GoogleSignInAccount?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<GoogleSignInAccount?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoogleSignInAccount? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignInAccount? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignInAccount?>(value),
    );
  }
}

String _$currentUserHash() => r'b1ca0e8c2a87bc7208ed00ebda7eaf88b7603e45';

@ProviderFor(isStatusAuthenticated)
final isStatusAuthenticatedProvider = IsStatusAuthenticatedProvider._();

final class IsStatusAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsStatusAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isStatusAuthenticatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isStatusAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isStatusAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isStatusAuthenticatedHash() =>
    r'515795120c9b53cf0d8af026d74d22a80d6fde8a';
