import 'package:tripship/features/profile/data/profile_model.dart';

/// Minimal fake for trust_ux tests: returns a fixed profile.
/// Use when a provider or widget needs a profile source.
class FakeProfileRepo {
  Profile? profile;

  FakeProfileRepo({this.profile});

  Profile? getCurrentProfile() => profile;
}
