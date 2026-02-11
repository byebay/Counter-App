# logbook_app_001

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## Bagaimana prinsip SRP membantu saat menambah fitur History Logger

Prinsip Single Responsibility (SRP) memisahkan tanggung jawab aplikasi ke bagian-bagian kecil.
Ketika fitur History Logger ditambahkan, SRP membantu dengan cara:

- Meminimalkan perubahan: Logika pencatatan riwayat dapat ditempatkan di modul/kelas terpisah, sehingga perubahan tidak menyebar ke bagian UI.
- Meningkatkan keterbacaan: Tanggung jawab jelas, memudahkan pemeliharaan.
- Karena tanggung jawab dipisah, menambah atau mengubah logger lebih kecil kemungkinannya memengaruhi fitur lain.

Dengan SRP, penambahan History Logger menjadi lebih terstruktur, aman, dan mudah diadaptasi.
