sealed class FormSubmitResult {
  const FormSubmitResult();
}

class FormSubmitSuccess extends FormSubmitResult {
  const FormSubmitSuccess(this.message);

  final String message;
}

class FormSubmitInvalid extends FormSubmitResult {
  const FormSubmitInvalid([this.message]);

  final String? message;
}

class FormSubmitIgnored extends FormSubmitResult {
  const FormSubmitIgnored();
}
