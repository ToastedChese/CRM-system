# PowerLink CRM

A Flutter-based CRM system.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

1.  **Clone the Repository**
    Clone the `gerhard/structure-proposal` branch to your local machine.

2.  **Get Dependencies**
    Open the project in your IDE (Android Studio or VS Code). Your IDE should prompt you to "Get dependencies". Click it.
    If you miss the pop-up, open the terminal in your IDE and run:
    ```sh
    flutter pub get
    ```

3.  **Set Up Environment Variables**
    In the root of the project, find the file named `.env.example`. Make a copy of this file and rename the copy to `.env`. Open the new `.env` file and fill in the required Supabase keys.

4.  **Run the App**
    Select a device (e.g., an emulator or a physical device) and press the run button.

## Security Note: Protecting Our Keys

The `.env` file contains your secret API keys. It is listed in the `.gitignore` file, which tells Git to intentionally ignore it. You must **never** commit this file to the repository.

If secret keys are exposed in a public repository, they can be found and used by anyone on the internet, leading to security breaches, unauthorized data access, and unexpected costs. Keeping secrets in a local `.env` file is a standard practice to prevent this.

## Default Flutter Documentation

For help getting started with Flutter development in general, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
