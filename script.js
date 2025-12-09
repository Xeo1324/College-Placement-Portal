document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('registrationForm');
  // ... other element selections

  form.addEventListener('submit', (event) => {
    event.preventDefault(); // Prevent the form from submitting
    clearErrors();
    let isValid = validateForm();

    if (isValid) {
      // On success, show a message and log data
      successMessage.textContent = 'Registration successful!';
      console.log('Form Data:', { /* ... */ });
      form.reset(); 
      setTimeout(() => { successMessage.textContent = ''; }, 5000);
    }
  });

  function validateForm() {
    let valid = true;
    if (nameInput.value.trim() === '') {
      showError(nameInput, 'Full Name is required.');
      valid = false;
    }
    // ... other validation checks
    return valid;
  }

  // ... showError and clearErrors functions
});
