import 'package:flutter/widgets.dart';

import '../../features/settings/domain/entities/app_language.dart';

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static const supportedLocales = [Locale('id'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    return scope?.localizations ?? const AppLocalizations(AppLanguage.id);
  }

  String tr(String key) {
    if (language == AppLanguage.id) return _id[key] ?? key;
    return _en[key] ?? key;
  }

  String trf(String key, Map<String, Object> values) {
    var translated = tr(key);
    for (final entry in values.entries) {
      translated = translated.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return translated;
  }

  String periodCount(int count) {
    return trf(
      count == 1 ? 'recorded_period_count_one' : 'recorded_period_count_many',
      {'count': count},
    );
  }

  String expenseRecordCount(int count) {
    return trf(
      count == 1 ? 'expense_record_count_one' : 'expense_record_count_many',
      {'count': count},
    );
  }

  String budgetDeleteMessage(String categoryName) {
    return trf('budget_delete_message', {'name': categoryName});
  }

  String periodDeleteMessage(String periodLabel) {
    return trf('period_delete_message', {'period': periodLabel});
  }

  String categoryDeleteMessage(String name) {
    return trf('category_plan_delete_message', {'name': name});
  }
}

class AppLocalizationsScope extends InheritedWidget {
  final AppLocalizations localizations;

  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) {
    return oldWidget.localizations.language != localizations.language;
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key) => l10n.tr(key);

  String trf(String key, Map<String, Object> values) => l10n.trf(key, values);
}

const _id = <String, String>{
  'failed_to_load_settings_error': 'Settings gagal dibaca: {error}',
  'storage_recovery_failed': 'Data Tidak Dapat Dipulihkan',
  'storage_recovery_failed_description':
      'File utama dan cadangan tidak dapat dibaca. Data asli tetap dipertahankan dan tidak ditimpa. Jangan hapus aplikasi sebelum file diperiksa atau dipulihkan.',
  'delete': 'Hapus',
  'cancel': 'Batal',
  'edit': 'Edit',
  'add': 'Tambah',
  'save': 'Simpan',
  'saving': 'Menyimpan...',
  'adding': 'Menambahkan...',
  'save_changes': 'Simpan Perubahan',
  'next': 'Lanjut',
  'start': 'Mulai',
  'create_period': 'Buat Periode',
  'create_financial_period': 'Buat Periode Keuangan',
  'add_financial_period': 'Tambah Periode Keuangan',
  'no_financial_period_yet': 'Belum Ada Periode Keuangan',
  'create_your_first_period_so_income_expenses_and_budget_categories_can_be':
      'Buat periode pertama supaya uang masuk, uang keluar, dan kategori anggaran bisa mulai dicatat.',
  'budget_cannot_be_created_yet': 'Anggaran Belum Bisa Dibuat',
  'add_a_financial_period_first_then_organize_budget_categories_for_that_pe':
      'Tambahkan periode keuangan dulu, lalu susun kategori anggaran untuk periode tersebut.',
  'create_a_financial_period_first': 'Buat periode keuangan dulu.',
  'create_a_financial_period_first_2': 'Buat periode keuangan dulu',
  'this_budget_category_cannot_be_deleted_because_it_already_has_expense_re':
      'Kategori anggaran ini belum bisa dihapus karena sudah punya catatan uang keluar.',
  'this_budget_category_cannot_be_deleted_because_it_already_has_history':
      'Kategori anggaran ini belum bisa dihapus karena sudah punya riwayat.',
  'budget_category_updated_successfully':
      'Kategori anggaran berhasil diperbarui.',
  'delete_budget_category': 'Hapus Kategori Anggaran?',
  'budget_category_deleted_successfully': 'Kategori anggaran berhasil dihapus.',
  'delete_financial_period': 'Hapus Periode Keuangan?',
  'financial_period_deleted_successfully': 'Periode keuangan berhasil dihapus.',
  'financial_period_updated_successfully':
      'Tanggal periode keuangan berhasil diperbarui.',
  'financial_period_period_added_successfully':
      'Periode keuangan {period} berhasil ditambahkan.',
  'period_options': 'Pilihan Periode',
  'edit_financial_period': 'Edit Periode Keuangan',
  'period_end_date': 'Tanggal Selesai Periode',
  'budget_categories': 'Kategori Anggaran',
  'amount': 'Jumlah Uang',
  'date': 'Tanggal',
  'financial_period': 'Periode Keuangan',
  'hide_financial_amounts': 'Sembunyikan Nominal Keuangan',
  'show_financial_amounts': 'Tampilkan Nominal Keuangan',
  'budget_category': 'Kategori Anggaran',
  'remaining_money_this_period': 'Sisa Uang Periode Ini',
  'record_income': 'Catat Uang Masuk',
  'record_expense': 'Catat Uang Keluar',
  'add_budget_category': 'Tambah Kategori Anggaran',
  'where_did_this_money_come_from': 'Dari Mana Uang Ini?',
  'what_was_it_used_for': 'Dipakai Untuk Apa?',
  'save_income': 'Simpan Uang Masuk',
  'save_expense': 'Simpan Uang Keluar',
  'save_budget_category': 'Simpan Kategori Anggaran',
  'choose_a_period_for_this_income_first':
      'Pilih periode untuk uang masuk ini dulu.',
  'choose_a_period_for_this_expense_first':
      'Pilih periode untuk uang keluar ini dulu.',
  'choose_the_budget_category_first': 'Pilih anggaran yang dipakai dulu.',
  'enter_the_income_amount_first': 'Isi jumlah uang masuk dulu.',
  'enter_the_expense_amount_first': 'Isi jumlah uang keluar dulu.',
  'enter_the_amount_first': 'Isi jumlah uangnya dulu.',
  'write_the_income_source_first': 'Tulis sumber uang masuknya dulu.',
  'write_what_the_money_was_used_for_first':
      'Tulis uangnya dipakai untuk apa dulu.',
  'fill_in_the_note_first': 'Isi catatannya dulu.',
  'income_recorded_successfully': 'Uang masuk berhasil dicatat.',
  'expense_recorded_successfully': 'Uang keluar berhasil dicatat.',
  'income_needs_to_be_placed_in_a_period_so_records_stay_organized':
      'Uang masuk perlu ditempatkan ke periode tertentu supaya catatannya rapi.',
  'expenses_need_to_be_placed_in_a_period_and_budget_category':
      'Uang keluar perlu ditempatkan ke periode dan kategori anggaran tertentu.',
  'create_a_financial_period_before_adding_a_budget_category':
      'Buat periode keuangan dulu sebelum menambah kategori anggaran.',
  'budget_category_name': 'Nama Kategori Anggaran',
  'choose_a_period_for_this_budget_category_first':
      'Pilih periode untuk kategori anggaran ini dulu.',
  'enter_the_budget_category_name_first': 'Isi nama kategori anggaran dulu.',
  'enter_the_budget_amount_first': 'Isi jumlah anggaran dulu.',
  'the_amount_exceeds_the_remaining_allocatable_balance_which_is_amount':
      'Jumlahnya melebihi sisa yang bisa dibagi, yaitu {amount}.',
  'budget_category_added_successfully':
      'Kategori anggaran berhasil ditambahkan.',
  'unallocated_balance': 'Sisa Yang Belum Dibagi',
  'income_details': 'Rincian Uang Masuk',
  'expense_details': 'Rincian Uang Keluar',
  'budget_details': 'Rincian Anggaran',
  'create_a_financial_period_first_to_view_income':
      'Buat periode keuangan dulu untuk melihat uang masuk.',
  'create_a_financial_period_first_to_view_expenses':
      'Buat periode keuangan dulu untuk melihat uang keluar.',
  'create_a_financial_period_first_to_view_the_budget':
      'Buat periode keuangan dulu untuk melihat anggaran.',
  'this_budget_was_not_found': 'Anggaran ini tidak ditemukan.',
  'total_income': 'Total Uang Masuk',
  'total_expense': 'Total Uang Keluar',
  'income_history': 'Riwayat Uang Masuk',
  'expense_history': 'Riwayat Uang Keluar',
  'delete_expense': 'Hapus Uang Keluar?',
  'title_will_be_removed_from_income_history_this_action_cannot_be_undone':
      '"{title}" akan dihapus dari riwayat uang masuk. Aksi ini tidak bisa dibatalkan.',
  'title_will_be_removed_from_expense_history_this_action_cannot_be_undone':
      '"{title}" akan dihapus dari riwayat uang keluar. Aksi ini tidak bisa dibatalkan.',
  'no_expenses_in_this_category_yet': 'Belum Ada Uang Keluar Di Kategori Ini',
  'no_expenses_recorded_in_this_period_yet':
      'Belum Ada Uang Keluar Di Periode Ini',
  'budget_change_history': 'Riwayat Perubahan Anggaran',
  'no_budget_changes_yet': 'Belum Ada Perubahan Anggaran',
  'budget_increased': 'Anggaran Ditambah',
  'budget_decreased': 'Anggaran Dikurangi',
  'budget_set': 'Anggaran Diset',
  'no_income_recorded_in_this_period_yet':
      'Belum Ada Uang Masuk Di Periode Ini',
  'delete_income': 'Hapus Uang Masuk?',
  'this_income_record_will_be_deleted_this_action_cannot_be_undone':
      'Uang masuk ini akan dihapus. Aksi ini tidak bisa dibatalkan.',
  'income_updated_successfully': 'Uang masuk berhasil diperbarui.',
  'income_deleted_successfully': 'Uang masuk berhasil dihapus.',
  'edit_expense': 'Edit Uang Keluar',
  'edit_income': 'Edit Uang Masuk',
  'financial_profile': 'Profil Keuangan',
  'dokido_user': 'Pengguna DokiDo',
  'recorded_periods': 'Periode Tercatat',
  'active_categories': 'Kategori Aktif',
  'income': 'Uang Masuk',
  'expense': 'Uang Keluar',
  'activity_history': 'Riwayat Aktivitas',
  'settings': 'Pengaturan',
  'search': 'Cari',
  'note': 'Catatan',
  'activity_filter': 'Filter Aktivitas',
  'activity_type': 'Jenis Aktivitas',
  'this_week': 'Minggu Ini',
  'this_month': 'Bulan Ini',
  'last_month': 'Bulan Lalu',
  'last_3_months': '3 Bulan Terakhir',
  'yesterday': 'Kemarin',
  'reset': 'Atur Ulang',
  'apply_filter': 'Terapkan Filter',
  'clear_search': 'Hapus Pencarian',
  'all': 'Semua',
  'budget_changes': 'Perubahan Anggaran',
  'no_activity_history_yet': 'Belum Ada Riwayat Aktivitas',
  'no_history_matches_the_filter':
      'Tidak Ada Riwayat Yang Sesuai Dengan Pencarian Atau Filter',
  'this_period_is_still_on_track': 'Uang Periode Ini Masih Aman',
  'this_period_needs_attention': 'Uang Periode Ini Perlu Dicek',
  'account_profile': 'Profil Akun',
  'local': 'Lokal',
  'display_name': 'Nama Yang Ditampilkan',
  'tracking_pattern': 'Pola Pencatatan',
  'flexible_financial_period_user':
      'Pengguna Dengan Periode Keuangan Fleksibel',
  'login_and_security': 'Masuk Akun & Keamanan',
  'not_active': 'Belum Aktif',
  'app_appearance': 'Tampilan Aplikasi',
  'app_preferences': 'Preferensi Aplikasi',
  'theme': 'Tema',
  'choose_color_theme': 'Pilih Tema Warna',
  'choose_language': 'Pilih Bahasa',
  'choose_currency': 'Pilih Mata Uang',
  'settings_updated_successfully': 'Pengaturan berhasil diperbarui.',
  'transaction_templates': 'Template Transaksi',
  'transaction_templates_settings_value': 'Template Cepat Dan Berulang',
  'export_report': 'Ekspor Laporan',
  'import_data': 'Impor Data',
  'feature_not_available_yet': 'Fitur ini belum tersedia.',
  'export_template': 'Template Ekspor',
  'dashboard_export_template': 'Dashboard',
  'dashboard_export_template_description':
      'Ringkasan visual dengan statistik, grafik, dan tabel.',
  'basic_export_template': 'Basic',
  'basic_export_template_description':
      'Tabel sederhana yang mudah dibaca dan diolah.',
  'export_template_selected': 'Template {template} dipilih.',
  'quick_templates': 'Template Cepat',
  'quick_template': 'Template Cepat',
  'recurring_transactions': 'Transaksi Berulang',
  'needs_to_be_recorded_today': 'Perlu Dicatat Hari Ini',
  'transactions_waiting_to_be_recorded': 'Transaksi Yang Menunggu Dicatat',
  'overdue': 'Terlewat',
  'due_today': 'Jatuh Tempo Hari Ini',
  'skip_this_time': 'Lewati Kali Ini',
  'recurring_occurrence_skipped':
      'Jadwal bulan ini dilewati dan tidak akan muncul lagi.',
  'edit_recurring_transaction': 'Edit Transaksi Berulang',
  'recurring_transaction_updated': 'Transaksi berulang berhasil diperbarui.',
  'recurring_transaction_paused': 'Transaksi berulang dijeda.',
  'recurring_transaction_resumed': 'Transaksi berulang diaktifkan kembali.',
  'recurring_transaction_ended': 'Jadwal transaksi berulang diakhiri.',
  'ended': 'Berakhir',
  'recurring_transaction_options': 'Pilihan Transaksi Berulang',
  'edit_schedule': 'Edit Jadwal',
  'end_schedule': 'Akhiri Jadwal',
  'active': 'Aktif',
  'paused': 'Dijeda',
  'pause': 'Jeda',
  'resume': 'Aktifkan',
  'transaction_name': 'Nama Transaksi',
  'target_budget_category': 'Kategori Anggaran Tujuan',
  'monthly_recording_date': 'Tanggal Pencatatan Bulanan',
  'day_1_to_31': '1–31',
  'active_from': 'Aktif Mulai',
  'ends_on': 'Berakhir Pada',
  'no_end_date': 'Tanpa Tanggal Berakhir',
  'choose_active_start_date': 'Pilih Tanggal Mulai Aktif',
  'choose_end_date': 'Pilih Tanggal Berakhir',
  'clear_end_date': 'Hapus Tanggal Berakhir',
  'local_reminder': 'Pengingat Lokal',
  'local_reminder_description':
      'Notifikasi tetap berjalan tanpa koneksi internet.',
  'reminder_hour': 'Jam Pengingat',
  'reminder_minute': 'Menit Pengingat',
  'enter_transaction_name': 'Isi nama transaksinya dulu.',
  'monthly_date_must_be_1_to_31':
      'Tanggal pencatatan harus antara 1 sampai 31.',
  'invalid_reminder_time': 'Jam pengingat tidak valid.',
  'recurring_notification_title': 'Waktunya Mencatat Transaksi',
  'recurring_notification_body':
      '"{title}" sudah jatuh tempo. Buka DokiDo untuk memeriksa dan mencatatnya.',
  'recurring_notification_private_body':
      'Ada transaksi berulang yang perlu diperiksa dan dicatat.',
  'recurring_notification_channel': 'Transaksi Berulang',
  'recurring_notification_channel_description':
      'Pengingat untuk draf uang masuk dan uang keluar berulang.',
  'enable_transaction_reminders': 'Aktifkan Pengingat Transaksi',
  'notification_permission_modal_description':
      'Izinkan notifikasi DokiDo melalui pengaturan perangkat supaya transaksi berulang tidak terlewat. Memilih Lain Kali akan menutup pengingat ini secara permanen.',
  'go_to_settings': 'Pergi Ke Pengaturan',
  'open_settings': 'Buka Pengaturan',
  'later': 'Lain Kali',
  'income_recorded_notification_not_allowed':
      'Uang masuk dan pengingat tersimpan, tetapi notifikasi belum diizinkan.',
  'expense_recorded_notification_not_allowed':
      'Uang keluar dan pengingat tersimpan, tetapi notifikasi belum diizinkan.',
  'recurring_updated_notification_not_allowed':
      'Perubahan tersimpan, tetapi notifikasi belum diizinkan.',
  'security': 'Keamanan',
  'app_lock': 'Kunci Aplikasi',
  'app_lock_active': 'Kunci Aplikasi Aktif',
  'app_lock_inactive': 'Kunci Aplikasi Nonaktif',
  'app_lock_active_description':
      'DokiDo meminta autentikasi sebelum menampilkan data keuangan.',
  'app_lock_inactive_description':
      'Data keuangan dapat dibuka tanpa PIN aplikasi.',
  'enable_app_lock': 'Aktifkan Kunci Aplikasi',
  'enable_app_lock_description':
      'Gunakan PIN 6 digit dan biometrik perangkat untuk melindungi akses ke DokiDo.',
  'create_app_lock_pin': 'Buat PIN Aplikasi',
  'create_app_lock_pin_description':
      'Masukkan 6 digit yang mudah Anda ingat tetapi sulit ditebak.',
  'confirm_app_lock_pin': 'Konfirmasi PIN',
  'confirm_app_lock_pin_description': 'Masukkan kembali PIN yang baru dibuat.',
  'pin_does_not_match': 'PIN tidak sama. Coba lagi.',
  'unlock_dokido': 'Buka DokiDo',
  'enter_app_lock_pin': 'Masukkan PIN aplikasi untuk melanjutkan.',
  'incorrect_pin': 'PIN salah.',
  'try_again_in_seconds': 'Coba lagi dalam {seconds} detik.',
  'forgot_pin': 'Lupa PIN?',
  'biometric_unlock_reason': 'Gunakan biometrik untuk membuka DokiDo.',
  'recover_pin_reason':
      'Konfirmasi identitas perangkat untuk membuat PIN DokiDo baru.',
  'device_auth_unavailable':
      'Autentikasi perangkat belum tersedia atau belum disiapkan.',
  'device_auth_locked':
      'Autentikasi perangkat terkunci sementara. Coba kembali nanti.',
  'authentication_failed': 'Autentikasi tidak berhasil.',
  'create_new_app_lock_pin': 'Buat PIN Baru',
  'create_new_app_lock_pin_description':
      'PIN lama akan diganti setelah PIN baru dikonfirmasi.',
  'recovered_pin_description':
      'Identitas berhasil dikonfirmasi. Buat PIN DokiDo yang baru.',
  'verify_app_lock_pin': 'Verifikasi PIN',
  'verify_it_is_you': 'Konfirmasi Identitas',
  'verify_pin_description':
      'Masukkan PIN aplikasi untuk melanjutkan perubahan keamanan.',
  'verifying': 'Memverifikasi...',
  'biometric_unlock': 'Buka Dengan Biometrik',
  'biometric_unlock_enabled': 'Biometrik aktif.',
  'biometric_unlock_disabled': 'Biometrik nonaktif.',
  'automatic_lock': 'Kunci Otomatis',
  'lock_immediately': 'Segera',
  'lock_after_1_minute': 'Setelah 1 Menit',
  'lock_after_30_minutes': 'Setelah 30 Menit',
  'change_pin': 'Ubah PIN',
  'change_pin_description': 'Ganti PIN aplikasi yang digunakan saat ini.',
  'lock_now': 'Kunci Sekarang',
  'lock_now_description': 'Tutup halaman ini dan langsung kunci DokiDo.',
  'disable_app_lock': 'Nonaktifkan Kunci Aplikasi',
  'disable_app_lock_description':
      'Hapus perlindungan PIN dan biometrik dari DokiDo.',
  'disable_app_lock_confirmation': 'Nonaktifkan Kunci Aplikasi?',
  'disable_app_lock_confirmation_description':
      'DokiDo dapat dibuka tanpa PIN atau biometrik setelah dinonaktifkan.',
  'disable': 'Nonaktifkan',
  'enable': 'Aktifkan',
  'app_lock_enabled_successfully': 'Kunci aplikasi berhasil diaktifkan.',
  'app_lock_disabled_successfully': 'Kunci aplikasi berhasil dinonaktifkan.',
  'pin_changed_successfully': 'PIN aplikasi berhasil diubah.',
  'biometric_not_available':
      'Biometrik belum tersedia atau belum didaftarkan di perangkat.',
  'enable_biometric_unlock': 'Aktifkan Biometrik?',
  'enable_biometric_unlock_description':
      'Gunakan sidik jari atau pengenalan wajah untuk membuka DokiDo lebih cepat.',
  'enable_biometric_reason':
      'Konfirmasi biometrik untuk mengaktifkan buka kunci DokiDo.',
  'verify_security_change_reason':
      'Konfirmasi biometrik untuk mengubah keamanan DokiDo.',
  'error_recurring_template_not_found':
      'Jadwal transaksi berulang sudah tidak tersedia.',
  'error_recurring_occurrence_already_processed':
      'Jadwal bulan ini sudah dicatat atau dilewati.',
  'use_template': 'Pakai Template',
  'save_as_template': 'Simpan Sebagai Template',
  'save_as_template_description':
      'Bisa dipakai lagi saat mencatat transaksi berikutnya.',
  'make_recurring': 'Jadikan Berulang',
  'make_recurring_description': 'Disiapkan sebagai draft setiap tanggal {day}.',
  'every_day_of_month': 'Setiap Tanggal {day}',
  'template_applied': 'Template berhasil dipakai.',
  'template_applied_choose_category':
      'Template berhasil dipakai. Pilih kategori anggaran yang sesuai.',
  'no_transaction_templates_yet': 'Belum Ada Template Transaksi',
  'transaction_template_empty_description':
      'Buat template dari form uang masuk atau uang keluar supaya transaksi yang sering dicatat bisa diisi lebih cepat.',
  'delete_transaction_template': 'Hapus Template Transaksi?',
  'delete_transaction_template_message':
      '"{title}" akan dihapus dari daftar template. Aksi ini tidak bisa dibatalkan.',
  'transaction_template_deleted': 'Template transaksi berhasil dihapus.',
  'primary': 'Utama',
  'palette': 'Palette',
  'currency': 'Mata Uang',
  'language_and_format': 'Bahasa Dan Format',
  'language': 'Bahasa',
  'currency_symbol': 'Simbol Mata Uang',
  'daily_tracking': 'Pencatatan Harian',
  'new_record_date': 'Tanggal Catatan Baru',
  'today': 'Hari Ini',
  'quick_add_default': 'Pilihan Tambah Cepat',
  'note_required': 'Catatan Harus Diisi',
  'off': 'Nonaktif',
  'period_and_budget': 'Periode Dan Anggaran',
  'period_start_date': 'Tanggal Mulai Periode',
  'the_22nd_of_every_month': 'Tanggal 22 Setiap Bulan',
  'default_template': 'Template Awal',
  'new_budget_calculation': 'Cara Hitung Anggaran Baru',
  'follows_income': 'Ikut Uang Masuk',
  'follows_income_2': 'Ikut Uang Masuk',
  'from_income': 'Dari Uang Masuk',
  'reminders': 'Pengingat',
  'daily_tracking_reminder': 'Ingatkan Catat Harian',
  'reminder_time': 'Jam Pengingat',
  'end_period_reminder': 'Pengingat Akhir Periode',
  'data': 'Data',
  'data_mode': 'Mode Data',
  'local_device_storage': 'Storage Lokal Perangkat',
  'download_data': 'Unduh Data',
  'online_sync': 'Sinkronisasi Online',
  'not_connected': 'Belum Tersambung',
  'financial_statistics': 'Statistik Keuangan',
  'period_summary': 'Ringkasan Periode Ini',
  'period_ends_in_days': 'Periode Selesai Dalam {days} Hari',
  'highest_spending_category': 'Kategori Terbesar',
  'categories_need_attention': 'Kategori Perlu Dicek',
  'most_flexible_category': 'Kategori Paling Longgar',
  'none': 'Tidak Ada',
  'no_recorded_periods_yet': 'Belum Ada Periode Tercatat',
  'no_financial_data_yet': 'Belum Ada Data Keuangan',
  'create_a_financial_period_first_the_summary_will_appear_here':
      'Buat periode keuangan dulu, nanti ringkasannya muncul di sini.',
  'choose_chart_type': 'Pilih Bentuk Grafik',
  'line_chart': 'Grafik Garis',
  'column_chart': 'Grafik Kolom',
  'expense_statistics': 'Statistik Uang Keluar',
  'no_expenses_yet': 'Belum Ada Uang Keluar',
  'expense_records_in_this_period_will_appear_here':
      'Catatan uang keluar di periode ini akan muncul di sini.',
  'choose_financial_period': 'Pilih Periode Keuangan',
  'budget_limit': 'Batas Anggaran',
  'remaining_money': 'Sisa Uang',
  'budget_category_options': 'Pilihan Kategori Anggaran',
  'expense_options': 'Pilihan Uang Keluar',
  'transaction_options': 'Pilihan Transaksi',
  'add_budget_amount': 'Tambah Anggaran',
  'reduce_budget_amount': 'Kurangi Anggaran',
  'set_budget_amount': 'Set Anggaran',
  'reason': 'Alasan',
  'write_the_reason_first': 'Tulis alasannya dulu.',
  'take_from_another_category': 'Ambil Dari Kategori Lain',
  'move_to_another_category': 'Pindahkan Ke Kategori Lain',
  'balance_with_another_category': 'Imbangi Dengan Kategori Lain',
  'do_not_use_another_category': 'Tidak Memakai Kategori Lain',
  'only_this_category_amount_will_change':
      'Nominal hanya berubah di kategori ini',
  'change_impact': 'Dampak Perubahan',
  'budget_adjusted_successfully': 'Anggaran berhasil disesuaikan.',
  'add_data': 'Tambah Data',
  'choose_the_type_of_record_you_want_to_create':
      'Pilih jenis catatan yang mau dibuat.',
  'new_budget_category': 'Kategori Anggaran Baru',
  'new_period': 'Periode Baru',
  'edit_budget_category': 'Edit Kategori Anggaran',
  'budget_amount': 'Jumlah Anggaran',
  'delete_budget_plan': 'Hapus Rencana Anggaran?',
  'budget_category_names_cannot_be_duplicated':
      'Nama kategori anggaran tidak boleh sama.',
  'choose_the_start_and_end_dates_first':
      'Pilih tanggal mulai dan selesai periode dulu.',
  'the_end_date_must_be_after_the_start_date':
      'Tanggal selesai periode harus setelah tanggal mulai.',
  'enter_the_opening_balance_first': 'Isi saldo awal periode dulu.',
  'write_the_opening_balance_source_first': 'Tulis sumber saldo awalnya dulu.',
  'add_at_least_one_initial_budget_plan':
      'Tambahkan minimal satu rencana anggaran awal.',
  'all_custom_percentages_must_be_greater_than_0':
      'Semua persentase buatanmu harus lebih dari 0.',
  'total_percentage_must_be_exactly_100': 'Total persentase harus tepat 100%.',
  'all_custom_amounts_must_be_greater_than_0':
      'Semua nominal buatanmu harus lebih dari 0.',
  'total_amount_cannot_exceed_the_opening_balance':
      'Total nominal tidak boleh melebihi saldo awal.',
  'total_amount_exceeds_the_opening_balance_of_amount':
      'Total nominal melebihi saldo awal {amount}.',
  'opening_balance_is_not_enough_to_cover_previous_deficit':
      'Saldo awal belum cukup untuk menombok minus periode sebelumnya.',
  'the_selected_date_overlaps_with_an_existing_period':
      'Tanggal yang dipilih bertabrakan dengan periode yang sudah ada.',
  'how_to_split_the_balance': 'Cara Membagi Saldo',
  'budget': 'Anggaran',
  'add_period': 'Tambah Periode',
  'save_period': 'Simpan Periode',
  'save_financial_period': 'Simpan Periode Keuangan',
  'saved_financial_period_cannot_be_deleted':
      'Periode yang sudah disimpan tidak bisa dihapus. Pastikan tanggal, saldo awal, dan rencana anggaran sudah benar.',
  'opening_balance': 'Saldo Awal',
  'opening_balance_source': 'Sumber Saldo Awal',
  'transfer_remaining_money_from_the_previous_period':
      'Transfer Sisa Periode Sebelumnya?',
  'cover_previous_period_deficit': 'Tombok Minus Periode Sebelumnya?',
  'transfer_remaining_money_from_period':
      'Transfer Sisa Dari Periode {period}?',
  'cover_previous_period_deficit_from_period': 'Tombok Minus Periode {period}?',
  'recorded_as_transfer_to_this_period':
      'Dicatat sebagai transfer ke periode ini.',
  'recorded_as_covering_previous_period':
      'Dicatat sebagai riwayat menombok periode itu.',
  'remaining_custom_amount': 'Sisa Nominal Yang Belum Dibagi',
  'initial_budget_plan': 'Rencana Anggaran Awal',
  'allocation_preview': 'Preview Alokasi',
  'allocation_formula': 'Rumus Alokasi',
  'popular_template': 'Template Populer',
  'customize': 'Atur Sendiri',
  'percentage': 'Persentase',
  'amount_2': 'Nominal',
  'rupiah': 'Rupiah',
  'adjust_with_every_income': 'Ikut Setiap Uang Masuk',
  'fixed_amount': 'Jumlah Tetap',
  'amount_changes_when_income_changes':
      'Jumlah Ikut Berubah Saat Uang Masuk Berubah',
  'amount_is_not_recalculated': 'Jumlah Tidak Dihitung Ulang',
  'end': 'Selesai',
  'choose_date': 'Pilih Tanggal',
  'choose_date_range': 'Pilih Rentang Tanggal',
  'custom_date_range': 'Rentang Tanggal Kustom',
  'clear_date_range': 'Hapus Rentang Tanggal',
  'filter_by_period': 'Filter Berdasarkan Periode',
  'apply': 'Terapkan',
  'choose_date_2': 'Pilih Tanggal',
  'choose_start_and_end_date': 'Pilih Tanggal Mulai Dan Selesai',
  'start_date_value': 'Mulai {date}',
  'default_budget': 'Anggaran Default',
  'review': 'Review',
  'profile': 'Profil',
  'preferences': 'Preferensi',
  'period': 'Periode',
  'category': 'Kategori',
  'allocation': 'Alokasi',
  'display_name_2': 'Nama Tampilan',
  'quick_introduction': 'Kenalan Sebentar',
  'this_name_will_be_used_in_your_profile_and_app_summaries':
      'Nama ini akan dipakai di profil dan ringkasan aplikasi.',
  'write_your_name': 'Tulis Nama Kamu',
  'choose_app_style': 'Pilih Gaya Aplikasi',
  'you_can_change_this_later_from_settings':
      'Kamu bisa ubah lagi nanti dari Settings.',
  'color_theme': 'Tema Warna',
  'create_your_first_period': 'Buat Periode Pertama',
  'all_money_records_will_go_into_the_period_you_choose':
      'Semua catatan uang akan masuk ke periode yang kamu pilih.',
  'start_date': 'Tanggal Mulai',
  'end_date': 'Tanggal Selesai',
  'enter_opening_balance': 'Masukkan Saldo Awal',
  'this_becomes_the_first_income_record_for_that_period':
      'Ini menjadi uang masuk pertama untuk periode tersebut.',
  'received_date': 'Tanggal Diterima',
  'set_up_budget_categories': 'Susun Kategori Anggaran',
  'use_the_categories_you_track_most_often':
      'Gunakan kategori yang paling sering kamu pantau.',
  'initial_categories': 'Kategori Awal',
  'choose_how_to_split_the_balance': 'Pilih Cara Membagi Saldo',
  'dokido_will_calculate_category_amounts_from_your_opening_balance':
      'DokiDo akan menghitung nominal kategori dari saldo awalmu.',
  'custom_percentage': 'Persentase Kustom',
  'custom_amount': 'Nominal Kustom',
  'review_before_starting': 'Cek Dulu Sebelum Mulai',
  'if_everything_looks_right_dokido_will_prepare_your_dashboard':
      'Kalau sudah benar, DokiDo akan menyiapkan dashboard kamu.',
  'name': 'Nama',
  'balance_source': 'Sumber Saldo',
  'unallocated_balance_2': 'Sisa Belum Dibagi',
  'category_name': 'Nama Kategori',
  'enter_percentages_or_amounts_for_each_category':
      'Isi persentase atau nominal sesuai kategori.',
  'enter_your_display_name_first': 'Isi nama tampilan dulu.',
  'choose_the_period_start_and_end_dates_first':
      'Pilih tanggal mulai dan selesai periode.',
  'the_end_date_must_be_after_the_start_date_2':
      'Tanggal selesai harus setelah tanggal mulai.',
  'enter_the_opening_balance_first_2': 'Isi saldo awal periode dulu.',
  'write_the_opening_balance_source_first_2':
      'Tulis sumber saldo awalnya dulu.',
  'add_at_least_one_budget_category':
      'Tambahkan minimal satu kategori anggaran.',
  'budget_category_names_cannot_be_duplicated_2':
      'Nama kategori anggaran tidak boleh sama.',
  'setup_complete_dokido_is_ready_to_use':
      'Setup selesai. DokiDo siap dipakai.',
  'there_must_be_at_least_one_budget_category':
      'Minimal harus ada satu kategori anggaran.',
  'all_percentages_must_be_greater_than_0':
      'Semua persentase harus lebih dari 0%.',
  'total_percentage_must_be_exactly_100_2':
      'Total persentase harus tepat 100%.',
  'all_amounts_must_be_greater_than_0': 'Semua nominal harus lebih dari 0.',
  'total_amount_cannot_exceed_the_opening_balance_2':
      'Total nominal tidak boleh melebihi saldo awal.',
  'example_feri': 'Contoh: Feri',
  'example_main_salary_freelance_bonus': 'Contoh: Gaji Utama, Freelance, Bonus',
  'opening_balance_source_2': 'Sumber Saldo Awal',
  'example_savings_balance_cash_or_this_month_s_money':
      'Contoh: Saldo Tabungan, Kas, Atau Uang Bulan Ini',
  'example_50': 'Contoh: 50',
  'example_1_000_000': 'Contoh: 1,000,000',
  'choose_the_currency_and_visual_style_that_feels_comfortable':
      'Pilih mata uang dan gaya tampilan yang nyaman untukmu.',
  'fresh_modern_and_closest_to_dokido_s_identity':
      'Segar, modern, dan paling dekat dengan identitas DokiDo.',
  'soft_lavender_with_warm_balance':
      'Lavender lembut dengan aksen hangat yang seimbang.',
  'cool_blue_clean_and_focused': 'Biru sejuk, bersih, dan fokus.',
  'bright_blue_for_clear_financial_focus':
      'Biru cerah untuk tampilan keuangan yang jelas.',
  'soft_blush_with_a_personal_feel': 'Blush lembut dengan rasa personal.',
  'fresh_mint_with_a_light_sunny_accent':
      'Mint segar dengan aksen cerah yang ringan.',
  'muted_green_with_soft_paper_tones':
      'Hijau kalem dengan nuansa kertas yang lembut.',
  'deep_green_with_mint_highlights':
      'Hijau dalam dengan highlight mint yang segar.',
  'calm_fresh_green_and_comfortable_for_daily_use':
      'Kalem, hijau segar, dan nyaman untuk dipakai harian.',
  'warm_personal_with_a_strong_accent':
      'Hangat, personal, dan punya aksen kuat.',
  'natural_soft_and_stable': 'Natural, lembut, dan terasa stabil.',
  'minimal_clean_and_calm_for_tidy_tracking':
      'Minimal, bersih, dan tenang untuk pencatatan rapi.',
  'bright_clean_with_a_bold_accent':
      'Cerah, bersih, dan punya aksen yang berani.',
  'recorded_period_count_one': '{count} periode tercatat',
  'recorded_period_count_many': '{count} periode tercatat',
  'expense_record_count_one': '{count} catatan uang keluar',
  'expense_record_count_many': '{count} catatan uang keluar',
  'budget_delete_message':
      'Kategori "{name}" akan dihapus dari periode ini. Aksi ini tidak bisa dibatalkan.',
  'period_delete_message':
      'Periode {period} akan dihapus bersama seluruh kategori anggaran, uang masuk, uang keluar, dan riwayat perubahan di dalamnya. Aksi ini tidak bisa dibatalkan.',
  'category_plan_delete_message':
      'Rencana "{name}" akan dihapus dari form periode ini.',
  'language_indonesian': 'Indonesia',
  'language_english': 'Inggris',
  'currency_idr': 'Rupiah',
  'currency_usd': 'Dolar AS',
  'theme_teal_balance': 'Teal Seimbang',
  'theme_fresh_mint': 'Mint Segar',
  'theme_rose_ledger': 'Catatan Mawar',
  'theme_sage_budget': 'Anggaran Sage',
  'theme_soft_linen': 'Linen Lembut',
  'theme_warm_signal': 'Sinyal Hangat',
  'theme_lavender_calm': 'Lavender Tenang',
  'theme_coastal_blue': 'Biru Pesisir',
  'theme_electric_blue': 'Biru Elektrik',
  'theme_blush_mauve': 'Mauve Lembut',
  'theme_mint_glow': 'Kilau Mint',
  'theme_olive_paper': 'Kertas Zaitun',
  'theme_forest_mint': 'Mint Hutan',
  'default_daily_needs': 'Kebutuhan Harian',
  'legacy_default_basic_needs': 'Kebutuhan Pokok',
  'default_savings_investment': 'Tabungan & Investasi',
  'default_entertainment': 'Hiburan',
  'default_others': 'Lain-Lain',
  'formula_priority': 'Prioritas',
  'formula_balanced': 'Seimbang',
  'formula_all_to_one': 'Semua saldo masuk ke satu kategori',
  'formula_main_then_other':
      'Utamakan kategori utama, sisanya untuk kebutuhan lain',
  'formula_main_and_support': 'Satu kategori utama, satu kategori pendukung',
  'formula_two_important': 'Untuk dua kebutuhan yang sama-sama penting',
  'formula_even_two': 'Dibagi rata untuk dua kategori',
  'formula_almost_all_main': 'Hampir semua saldo untuk prioritas utama',
  'formula_main_flexible_savings': 'Kebutuhan utama, fleksibel, dan tabungan',
  'formula_main_two_balanced':
      'Kebutuhan utama dengan dua kategori pendukung seimbang',
  'formula_required_costs_high': 'Cocok saat biaya wajib sedang besar',
  'formula_required_high_two_funded':
      'Biaya wajib besar, dua kategori lain tetap terjaga',
  'formula_lean_essential_high': 'Mode hemat saat biaya pokok tinggi',
  'formula_most_required': 'Mayoritas saldo untuk kebutuhan wajib',
  'formula_flexible_two_others':
      'Lebih longgar untuk dua kategori selain kebutuhan utama',
  'formula_needs_flexible_entertainment_others':
      'Kebutuhan, fleksibel, hiburan, dan lain-lain',
  'formula_503020_four': 'Adaptasi 50/30/20 dengan dua kategori pendukung',
  'formula_balanced_four': 'Lebih seimbang untuk empat kategori',
  'formula_large_flexible_two_small':
      'Kategori fleksibel besar, dua kategori kecil seimbang',
  'formula_high_required_controlled':
      'Biaya wajib tinggi, kategori lain dikontrol',
  'formula_603010_four': 'Adaptasi 60/30/10 dengan dua kategori kecil',
  'formula_high_daily_expensive':
      'Kebutuhan harian tinggi untuk biaya hidup mahal',
  'formula_prioritize_required': 'Prioritas biaya wajib',
  'formula_very_strict_main': 'Mode sangat ketat untuk prioritas utama',
  'formula_even_four': 'Pembagian rata untuk empat kategori',
  'formula_503020_five': 'Adaptasi 50/30/20 untuk lima kategori',
  'formula_lighter_main': 'Prioritas utama lebih ringan',
  'formula_dominant_required_small_reserve':
      'Biaya wajib dominan dengan cadangan kecil',
  'formula_lean_five': 'Mode hemat untuk lima kategori',
  'formula_gradual_priority': 'Tangga prioritas bertahap',
  'formula_first_larger_rest_even':
      'Kategori pertama lebih besar, sisanya dibagi rata',
  'formula_even_categories': 'Dibagi rata untuk {count} kategori',
  'weekday_mon': 'Sen',
  'weekday_tue': 'Sel',
  'weekday_wed': 'Rab',
  'weekday_thu': 'Kam',
  'weekday_fri': 'Jum',
  'weekday_sat': 'Sab',
  'weekday_sun': 'Min',
  'month_short_1': 'Jan',
  'month_short_2': 'Feb',
  'month_short_3': 'Mar',
  'month_short_4': 'Apr',
  'month_short_5': 'Mei',
  'month_short_6': 'Jun',
  'month_short_7': 'Jul',
  'month_short_8': 'Agu',
  'month_short_9': 'Sep',
  'month_short_10': 'Okt',
  'month_short_11': 'Nov',
  'month_short_12': 'Des',
  'month_long_1': 'Januari',
  'month_long_2': 'Februari',
  'month_long_3': 'Maret',
  'month_long_4': 'April',
  'month_long_5': 'Mei',
  'month_long_6': 'Juni',
  'month_long_7': 'Juli',
  'month_long_8': 'Agustus',
  'month_long_9': 'September',
  'month_long_10': 'Oktober',
  'month_long_11': 'November',
  'month_long_12': 'Desember',
  'error_budget_negative': 'Nominal anggaran tidak boleh kurang dari nol.',
  'error_source_budget_insufficient':
      'Nominal anggaran sumber tidak mencukupi.',
  'error_budget_has_history': 'Anggaran sudah memiliki riwayat.',
  'error_period_end_before_start':
      'Tanggal selesai periode harus setelah tanggal mulai.',
  'error_period_overlap':
      'Tanggal yang dipilih bertabrakan dengan periode lain.',
  'transfer_to_period': 'Transfer ke periode {period}',
  'transfer_from_period': 'Transfer dari periode {period}',
  'covered_by_period': 'Ditombok dari periode {period}',
  'covering_period': 'Menombok periode {period}',
  'choose': 'Pilih',
  'change': 'Ubah',
  'create': 'Buat',
  'set': 'Atur',
  'restore': 'Pulihkan',
  'continue': 'Lanjutkan',
  'data_and_storage': 'Data & Penyimpanan',
  'local_backup': 'Backup Lokal',
  'backup_storage': 'Penyimpanan Backup',
  'backup_location': 'Lokasi Backup',
  'backup_location_not_selected': 'Belum ada folder yang dipilih',
  'backup_password': 'Kata Sandi Backup',
  'backup_password_hint': 'Minimal 8 karakter',
  'backup_password_configured': 'Kata sandi sudah dikonfigurasi',
  'backup_password_missing_description': 'Belum ada kata sandi backup',
  'confirm_backup_password': 'Konfirmasi Kata Sandi',
  'repeat_backup_password': 'Ulangi kata sandi backup',
  'create_backup_password': 'Buat Kata Sandi Backup',
  'enter_backup_password': 'Masukkan Kata Sandi Backup',
  'save_password': 'Simpan Kata Sandi',
  'backup_password_saved': 'Kata sandi backup berhasil disimpan.',
  'backup_password_recovery_warning':
      'Simpan kata sandi ini dengan aman. Backup tidak dapat dipulihkan jika kata sandinya lupa.',
  'backup_password_too_short':
      'Kata sandi backup harus berisi minimal 8 karakter.',
  'backup_passwords_do_not_match': 'Konfirmasi kata sandi belum sama.',
  'backup_password_or_file_invalid':
      'Kata sandi salah atau file backup tidak dapat dibaca.',
  'backup_file_invalid': 'File ini bukan backup DokiDo yang valid.',
  'backup_password_not_configured': 'Buat kata sandi backup terlebih dahulu.',
  'backup_credential_mismatch':
      'Kunci backup tidak cocok. Atur ulang kata sandi backup.',
  'backup_folder_not_configured': 'Pilih lokasi backup terlebih dahulu.',
  'backup_settings_unavailable': 'Pengaturan backup belum dapat dibaca.',
  'backup_operation_failed': 'Proses backup gagal diselesaikan.',
  'backup_operation_failed_with_reason': 'Backup gagal: {reason}',
  'automatic_backup': 'Backup Otomatis',
  'backup_frequency': 'Frekuensi Backup',
  'backup_frequency_off': 'Nonaktif',
  'backup_frequency_daily': 'Setiap Hari',
  'backup_frequency_weekly': 'Setiap Minggu',
  'backup_frequency_monthly': 'Setiap Bulan',
  'automatic_backup_updated': 'Jadwal backup otomatis berhasil diperbarui.',
  'backup_actions': 'Tindakan Backup',
  'backup_now': 'Backup Sekarang',
  'backup_now_description': 'Buat salinan terbaru ke folder backup.',
  'restore_latest_backup': 'Pulihkan Backup Terbaru',
  'restore_latest_backup_description':
      'Gunakan salinan terbaru dari folder backup.',
  'choose_another_backup_file': 'Pilih File Backup Lain',
  'choose_another_backup_file_description':
      'Pulihkan file .dokido dari lokasi lain.',
  'processing_backup': 'Sedang memproses data dengan aman...',
  'backup_ready': 'Backup Siap Digunakan',
  'backup_not_configured': 'Backup Belum Dikonfigurasi',
  'no_backup_yet': 'Belum pernah membuat backup',
  'last_backup_value': 'Backup terakhir {date}, {time}',
  'backup_created_successfully': 'Backup terbaru berhasil dibuat.',
  'latest_backup_not_found': 'File backup terbaru belum ditemukan.',
  'restore_preview': 'Pratinjau Pemulihan',
  'backup_file': 'File Backup',
  'backup_created_at': 'Dibuat Pada',
  'financial_periods': 'Periode Keuangan',
  'transactions': 'Transaksi',
  'restore_replaces_current_data_warning':
      'Seluruh data keuangan saat ini akan diganti. PIN dan pengaturan App Lock tetap dipertahankan.',
  'backup_restored_successfully': 'Data DokiDo berhasil dipulihkan.',
  'change_display_name': 'Ubah Nama Yang Ditampilkan',
  'display_name_hint': 'Masukkan nama yang ingin ditampilkan',
  'display_name_required': 'Nama yang ditampilkan wajib diisi.',
  'general_info': 'Informasi Umum',
  'terms_and_conditions': 'Syarat & Ketentuan',
  'privacy_policy': 'Kebijakan Privasi',
  'version': 'Versi',
  'powered_by_niskala': 'Powered by Niskala.dev',
  'terms_and_conditions_content':
      'Terakhir diperbarui: Juli 2026\n\n'
      'DokiDo adalah aplikasi pencatatan keuangan pribadi yang bekerja secara lokal di perangkat. Dengan menggunakan DokiDo, pengguna bertanggung jawab atas kebenaran data yang dicatat dan keputusan keuangan yang dibuat berdasarkan data tersebut.\n\n'
      'DokiDo tidak menyediakan layanan perbankan, investasi, perpajakan, atau nasihat keuangan profesional. Perhitungan aplikasi membantu pencatatan dan perencanaan, tetapi tetap perlu diperiksa oleh pengguna.\n\n'
      'Pengguna bertanggung jawab menjaga perangkat, PIN aplikasi, kata sandi backup, dan file backup. File backup yang kata sandinya terlupa tidak dapat dipulihkan.\n\n'
      'Fitur dan struktur data dapat berubah selama masa beta. Niskala.dev berupaya menjaga keandalan aplikasi, tetapi pengguna tetap disarankan membuat backup berkala.',
  'privacy_policy_content':
      'Terakhir diperbarui: Juli 2026\n\n'
      'DokiDo dirancang sebagai aplikasi offline. Data keuangan utama disimpan secara terenkripsi di perangkat dan tidak dikirim ke server DokiDo.\n\n'
      'Izin notifikasi digunakan untuk pengingat transaksi dan peringatan keuangan yang dipilih. Akses folder backup diberikan melalui pemilih folder Android dan hanya berlaku untuk folder yang disetujui pengguna.\n\n'
      'File backup dienkripsi dengan kata sandi backup. Jika pengguna menyimpan file ke layanan cloud atau membagikannya, pengelolaan file tersebut mengikuti kebijakan layanan tujuan.\n\n'
      'DokiDo tidak mengakses data biometrik mentah. Verifikasi biometrik dilakukan oleh sistem operasi perangkat.',
  'notifications': 'Notifikasi',
  'mark_all_as_read': 'Tandai Semua Dibaca',
  'unread': 'Belum Dibaca',
  'notifications_could_not_be_loaded': 'Notifikasi belum dapat dimuat.',
  'no_notifications_yet': 'Belum ada notifikasi.',
  'no_unread_notifications': 'Semua notifikasi sudah dibaca.',
  'delete_notification': 'Hapus Notifikasi?',
  'delete_notification_description': 'Notifikasi ini akan dihapus dari DokiDo.',
  'record_now': 'Catat Sekarang',
  'view_budget': 'Lihat Anggaran',
  'fix': 'Perbaiki',
  'view_period': 'Lihat Periode',
  'notification_recurring_title': '{title} Perlu Dicatat',
  'notification_recurring_body': '{amount} dijadwalkan pada {date}.',
  'notification_recurring_category_body':
      '{amount} dijadwalkan pada {date} dari {category}.',
  'notification_budget_warning_title': 'Anggaran Hampir Habis',
  'notification_budget_warning_body': '{category} sudah terpakai {percent}%.',
  'notification_budget_exceeded_title': 'Anggaran Terlampaui',
  'notification_budget_exceeded_body':
      '{category} sudah mencapai {percent}% dari batas anggaran.',
  'notification_backup_failed_title': 'Backup Otomatis Gagal',
  'notification_backup_failed_body':
      'Folder backup tidak dapat diakses. Pilih ulang lokasi backup.',
  'notification_period_ending_title': 'Periode Segera Berakhir',
  'notification_period_ending_today_body':
      'Periode {period} berakhir hari ini.',
  'notification_period_ending_one_day_body':
      'Periode {period} berakhir dalam 1 hari.',
  'notification_period_ending_many_days_body':
      'Periode {period} berakhir dalam {days} hari.',
  'financial_alert_notification_channel': 'Peringatan Keuangan',
  'financial_alert_notification_channel_description':
      'Peringatan anggaran, periode, dan backup DokiDo.',
  'private_notification_title': 'Pemberitahuan DokiDo',
  'private_notification_body':
      'Buka DokiDo untuk melihat pemberitahuan terbaru.',
};

const _en = <String, String>{
  'failed_to_load_settings_error': 'Failed to load settings: {error}',
  'storage_recovery_failed': 'Data Could Not Be Recovered',
  'storage_recovery_failed_description':
      'The primary and backup files could not be read. The original data has been preserved and was not overwritten. Do not uninstall the app before the files are inspected or recovered.',
  'delete': 'Delete',
  'cancel': 'Cancel',
  'edit': 'Edit',
  'add': 'Add',
  'save': 'Save',
  'saving': 'Saving...',
  'adding': 'Adding...',
  'save_changes': 'Save Changes',
  'next': 'Next',
  'start': 'Start',
  'create_period': 'Create Period',
  'create_financial_period': 'Create Financial Period',
  'add_financial_period': 'Add Financial Period',
  'no_financial_period_yet': 'No Financial Period Yet',
  'create_your_first_period_so_income_expenses_and_budget_categories_can_be':
      'Create your first period so income, expenses, and budget categories can be tracked.',
  'budget_cannot_be_created_yet': 'Budget Cannot Be Created Yet',
  'add_a_financial_period_first_then_organize_budget_categories_for_that_pe':
      'Add a financial period first, then organize budget categories for that period.',
  'create_a_financial_period_first': 'Create a financial period first.',
  'create_a_financial_period_first_2': 'Create a financial period first',
  'this_budget_category_cannot_be_deleted_because_it_already_has_expense_re':
      'This budget category cannot be deleted because it already has expense records.',
  'this_budget_category_cannot_be_deleted_because_it_already_has_history':
      'This budget category cannot be deleted because it already has history.',
  'budget_category_updated_successfully':
      'Budget category updated successfully.',
  'delete_budget_category': 'Delete Budget Category?',
  'budget_category_deleted_successfully':
      'Budget category deleted successfully.',
  'delete_financial_period': 'Delete Financial Period?',
  'financial_period_deleted_successfully':
      'Financial period deleted successfully.',
  'financial_period_updated_successfully':
      'Financial period dates updated successfully.',
  'financial_period_period_added_successfully':
      'Financial period {period} added successfully.',
  'period_options': 'Period Options',
  'edit_financial_period': 'Edit Financial Period',
  'period_end_date': 'Period End Date',
  'budget_categories': 'Budget Categories',
  'amount': 'Amount',
  'date': 'Date',
  'financial_period': 'Financial Period',
  'hide_financial_amounts': 'Hide Financial Amounts',
  'show_financial_amounts': 'Show Financial Amounts',
  'budget_category': 'Budget Category',
  'remaining_money_this_period': 'Remaining Money This Period',
  'record_income': 'Record Income',
  'record_expense': 'Record Expense',
  'add_budget_category': 'Add Budget Category',
  'where_did_this_money_come_from': 'Where Did This Money Come From?',
  'what_was_it_used_for': 'What Was It Used For?',
  'save_income': 'Save Income',
  'save_expense': 'Save Expense',
  'save_budget_category': 'Save Budget Category',
  'choose_a_period_for_this_income_first':
      'Choose a period for this income first.',
  'choose_a_period_for_this_expense_first':
      'Choose a period for this expense first.',
  'choose_the_budget_category_first': 'Choose the budget category first.',
  'enter_the_income_amount_first': 'Enter the income amount first.',
  'enter_the_expense_amount_first': 'Enter the expense amount first.',
  'enter_the_amount_first': 'Enter the amount first.',
  'write_the_income_source_first': 'Write the income source first.',
  'write_what_the_money_was_used_for_first':
      'Write what the money was used for first.',
  'fill_in_the_note_first': 'Fill in the note first.',
  'income_recorded_successfully': 'Income recorded successfully.',
  'expense_recorded_successfully': 'Expense recorded successfully.',
  'income_needs_to_be_placed_in_a_period_so_records_stay_organized':
      'Income needs to be placed in a period so records stay organized.',
  'expenses_need_to_be_placed_in_a_period_and_budget_category':
      'Expenses need to be placed in a period and budget category.',
  'create_a_financial_period_before_adding_a_budget_category':
      'Create a financial period before adding a budget category.',
  'budget_category_name': 'Budget Category Name',
  'choose_a_period_for_this_budget_category_first':
      'Choose a period for this budget category first.',
  'enter_the_budget_category_name_first':
      'Enter the budget category name first.',
  'enter_the_budget_amount_first': 'Enter the budget amount first.',
  'the_amount_exceeds_the_remaining_allocatable_balance_which_is_amount':
      'The amount exceeds the remaining allocatable balance, which is {amount}.',
  'budget_category_added_successfully': 'Budget category added successfully.',
  'unallocated_balance': 'Unallocated Balance',
  'income_details': 'Income Details',
  'expense_details': 'Expense Details',
  'budget_details': 'Budget Details',
  'create_a_financial_period_first_to_view_income':
      'Create a financial period first to view income.',
  'create_a_financial_period_first_to_view_expenses':
      'Create a financial period first to view expenses.',
  'create_a_financial_period_first_to_view_the_budget':
      'Create a financial period first to view the budget.',
  'this_budget_was_not_found': 'This budget was not found.',
  'total_income': 'Total Income',
  'total_expense': 'Total Expense',
  'income_history': 'Income History',
  'expense_history': 'Expense History',
  'delete_expense': 'Delete Expense?',
  'title_will_be_removed_from_income_history_this_action_cannot_be_undone':
      '"{title}" will be removed from income history. This action cannot be undone.',
  'title_will_be_removed_from_expense_history_this_action_cannot_be_undone':
      '"{title}" will be removed from expense history. This action cannot be undone.',
  'no_expenses_in_this_category_yet': 'No Expenses In This Category Yet',
  'no_expenses_recorded_in_this_period_yet':
      'No Expenses Recorded In This Period Yet',
  'budget_change_history': 'Budget Change History',
  'no_budget_changes_yet': 'No Budget Changes Yet',
  'budget_increased': 'Budget Increased',
  'budget_decreased': 'Budget Decreased',
  'budget_set': 'Budget Set',
  'no_income_recorded_in_this_period_yet':
      'No Income Recorded In This Period Yet',
  'delete_income': 'Delete Income?',
  'this_income_record_will_be_deleted_this_action_cannot_be_undone':
      'This income record will be deleted. This action cannot be undone.',
  'income_updated_successfully': 'Income updated successfully.',
  'income_deleted_successfully': 'Income deleted successfully.',
  'edit_expense': 'Edit Expense',
  'edit_income': 'Edit Income',
  'financial_profile': 'Financial Profile',
  'dokido_user': 'DokiDo User',
  'recorded_periods': 'Recorded Periods',
  'active_categories': 'Active Categories',
  'income': 'Income',
  'expense': 'Expense',
  'activity_history': 'Activity History',
  'settings': 'Settings',
  'search': 'Search',
  'note': 'Note',
  'activity_filter': 'Activity Filter',
  'activity_type': 'Activity Type',
  'this_week': 'This Week',
  'this_month': 'This Month',
  'last_month': 'Last Month',
  'last_3_months': 'Last 3 Months',
  'yesterday': 'Yesterday',
  'reset': 'Reset',
  'apply_filter': 'Apply Filter',
  'clear_search': 'Clear Search',
  'all': 'All',
  'budget_changes': 'Budget Changes',
  'no_activity_history_yet': 'No Activity History Yet',
  'no_history_matches_the_filter': 'No History Matches The Search Or Filter',
  'this_period_is_still_on_track': 'This Period Is Still On Track',
  'this_period_needs_attention': 'This Period Needs Attention',
  'account_profile': 'Account Profile',
  'local': 'Local',
  'display_name': 'Display Name',
  'tracking_pattern': 'Tracking Pattern',
  'flexible_financial_period_user': 'User With Flexible Financial Periods',
  'login_and_security': 'Login & Security',
  'not_active': 'Not Active',
  'app_appearance': 'App Appearance',
  'app_preferences': 'App Preferences',
  'theme': 'Theme',
  'choose_color_theme': 'Choose Color Theme',
  'choose_language': 'Choose Language',
  'choose_currency': 'Choose Currency',
  'settings_updated_successfully': 'Settings updated successfully.',
  'transaction_templates': 'Transaction Templates',
  'transaction_templates_settings_value': 'Quick And Recurring Templates',
  'export_report': 'Export Report',
  'import_data': 'Import Data',
  'feature_not_available_yet': 'This feature is not available yet.',
  'export_template': 'Export Template',
  'dashboard_export_template': 'Dashboard',
  'dashboard_export_template_description':
      'A visual summary with statistics, charts, and tables.',
  'basic_export_template': 'Basic',
  'basic_export_template_description':
      'A simple table that is easy to read and process.',
  'export_template_selected': '{template} template selected.',
  'quick_templates': 'Quick Templates',
  'quick_template': 'Quick Template',
  'recurring_transactions': 'Recurring Transactions',
  'needs_to_be_recorded_today': 'Needs To Be Recorded Today',
  'transactions_waiting_to_be_recorded': 'Transactions Waiting To Be Recorded',
  'overdue': 'Overdue',
  'due_today': 'Due Today',
  'skip_this_time': 'Skip This Time',
  'recurring_occurrence_skipped':
      'This month’s schedule was skipped and will not appear again.',
  'edit_recurring_transaction': 'Edit Recurring Transaction',
  'recurring_transaction_updated':
      'Recurring transaction updated successfully.',
  'recurring_transaction_paused': 'Recurring transaction paused.',
  'recurring_transaction_resumed': 'Recurring transaction resumed.',
  'recurring_transaction_ended': 'The recurring transaction schedule ended.',
  'ended': 'Ended',
  'recurring_transaction_options': 'Recurring Transaction Options',
  'edit_schedule': 'Edit Schedule',
  'end_schedule': 'End Schedule',
  'active': 'Active',
  'paused': 'Paused',
  'pause': 'Pause',
  'resume': 'Resume',
  'transaction_name': 'Transaction Name',
  'target_budget_category': 'Target Budget Category',
  'monthly_recording_date': 'Monthly Recording Date',
  'day_1_to_31': '1–31',
  'active_from': 'Active From',
  'ends_on': 'Ends On',
  'no_end_date': 'No End Date',
  'choose_active_start_date': 'Choose Active Start Date',
  'choose_end_date': 'Choose End Date',
  'clear_end_date': 'Clear End Date',
  'local_reminder': 'Local Reminder',
  'local_reminder_description':
      'Notifications keep working without an internet connection.',
  'reminder_hour': 'Reminder Hour',
  'reminder_minute': 'Reminder Minute',
  'enter_transaction_name': 'Enter the transaction name first.',
  'monthly_date_must_be_1_to_31':
      'The recording date must be between 1 and 31.',
  'invalid_reminder_time': 'The reminder time is invalid.',
  'recurring_notification_title': 'Time To Record A Transaction',
  'recurring_notification_body':
      '"{title}" is due. Open DokiDo to review and record it.',
  'recurring_notification_private_body':
      'A recurring transaction needs to be reviewed and recorded.',
  'recurring_notification_channel': 'Recurring Transactions',
  'recurring_notification_channel_description':
      'Reminders for recurring income and expense drafts.',
  'enable_transaction_reminders': 'Enable Transaction Reminders',
  'notification_permission_modal_description':
      'Allow DokiDo notifications in your device settings so recurring transactions are not missed. Choosing Later will permanently dismiss this reminder.',
  'go_to_settings': 'Go To Settings',
  'open_settings': 'Open Settings',
  'later': 'Later',
  'income_recorded_notification_not_allowed':
      'The income and reminder were saved, but notifications are not allowed.',
  'expense_recorded_notification_not_allowed':
      'The expense and reminder were saved, but notifications are not allowed.',
  'recurring_updated_notification_not_allowed':
      'Changes were saved, but notifications are not allowed.',
  'security': 'Security',
  'app_lock': 'App Lock',
  'app_lock_active': 'App Lock Active',
  'app_lock_inactive': 'App Lock Inactive',
  'app_lock_active_description':
      'DokiDo requires authentication before showing financial data.',
  'app_lock_inactive_description':
      'Financial data can be opened without an app PIN.',
  'enable_app_lock': 'Enable App Lock',
  'enable_app_lock_description':
      'Use a 6-digit PIN and device biometrics to protect access to DokiDo.',
  'create_app_lock_pin': 'Create App PIN',
  'create_app_lock_pin_description':
      'Enter 6 digits that are easy for you to remember but difficult to guess.',
  'confirm_app_lock_pin': 'Confirm PIN',
  'confirm_app_lock_pin_description': 'Enter the new PIN again.',
  'pin_does_not_match': 'PINs do not match. Try again.',
  'unlock_dokido': 'Unlock DokiDo',
  'enter_app_lock_pin': 'Enter the app PIN to continue.',
  'incorrect_pin': 'Incorrect PIN.',
  'try_again_in_seconds': 'Try again in {seconds} seconds.',
  'forgot_pin': 'Forgot PIN?',
  'biometric_unlock_reason': 'Use biometrics to unlock DokiDo.',
  'recover_pin_reason':
      'Confirm your device identity to create a new DokiDo PIN.',
  'device_auth_unavailable':
      'Device authentication is unavailable or has not been configured.',
  'device_auth_locked':
      'Device authentication is temporarily locked. Try again later.',
  'authentication_failed': 'Authentication was unsuccessful.',
  'create_new_app_lock_pin': 'Create New PIN',
  'create_new_app_lock_pin_description':
      'The current PIN will be replaced after confirming the new PIN.',
  'recovered_pin_description':
      'Your identity was confirmed. Create a new DokiDo PIN.',
  'verify_app_lock_pin': 'Verify PIN',
  'verify_it_is_you': 'Confirm Your Identity',
  'verify_pin_description':
      'Enter the app PIN to continue changing security settings.',
  'verifying': 'Verifying...',
  'biometric_unlock': 'Unlock With Biometrics',
  'biometric_unlock_enabled': 'Biometric unlock enabled.',
  'biometric_unlock_disabled': 'Biometric unlock disabled.',
  'automatic_lock': 'Automatic Lock',
  'lock_immediately': 'Immediately',
  'lock_after_1_minute': 'After 1 Minute',
  'lock_after_30_minutes': 'After 30 Minutes',
  'change_pin': 'Change PIN',
  'change_pin_description': 'Replace the current app PIN.',
  'lock_now': 'Lock Now',
  'lock_now_description': 'Close this page and lock DokiDo immediately.',
  'disable_app_lock': 'Disable App Lock',
  'disable_app_lock_description':
      'Remove PIN and biometric protection from DokiDo.',
  'disable_app_lock_confirmation': 'Disable App Lock?',
  'disable_app_lock_confirmation_description':
      'DokiDo can be opened without a PIN or biometrics after disabling it.',
  'disable': 'Disable',
  'enable': 'Enable',
  'app_lock_enabled_successfully': 'App Lock enabled successfully.',
  'app_lock_disabled_successfully': 'App Lock disabled successfully.',
  'pin_changed_successfully': 'App PIN changed successfully.',
  'biometric_not_available':
      'Biometrics are unavailable or not enrolled on this device.',
  'enable_biometric_unlock': 'Enable Biometrics?',
  'enable_biometric_unlock_description':
      'Use fingerprint or face recognition to unlock DokiDo faster.',
  'enable_biometric_reason':
      'Confirm biometrics to enable DokiDo biometric unlock.',
  'verify_security_change_reason':
      'Confirm biometrics to change DokiDo security.',
  'error_recurring_template_not_found':
      'The recurring transaction schedule is no longer available.',
  'error_recurring_occurrence_already_processed':
      'This month’s schedule was already recorded or skipped.',
  'use_template': 'Use Template',
  'save_as_template': 'Save As Template',
  'save_as_template_description':
      'Use it again when recording the next transaction.',
  'make_recurring': 'Make Recurring',
  'make_recurring_description': 'Prepared as a draft every day {day}.',
  'every_day_of_month': 'Every Day {day}',
  'template_applied': 'Template applied successfully.',
  'template_applied_choose_category':
      'Template applied. Choose the matching budget category.',
  'no_transaction_templates_yet': 'No Transaction Templates Yet',
  'transaction_template_empty_description':
      'Create templates from income or expense forms so frequent transactions can be filled faster.',
  'delete_transaction_template': 'Delete Transaction Template?',
  'delete_transaction_template_message':
      '"{title}" will be removed from templates. This action cannot be undone.',
  'transaction_template_deleted': 'Transaction template deleted successfully.',
  'primary': 'Primary',
  'palette': 'Palette',
  'currency': 'Currency',
  'language_and_format': 'Language & Format',
  'language': 'Language',
  'currency_symbol': 'Currency Symbol',
  'daily_tracking': 'Daily Tracking',
  'new_record_date': 'New Record Date',
  'today': 'Today',
  'quick_add_default': 'Quick Add Default',
  'note_required': 'Note Required',
  'off': 'Off',
  'period_and_budget': 'Period & Budget',
  'period_start_date': 'Period Start Date',
  'the_22nd_of_every_month': 'The 22nd Of Every Month',
  'default_template': 'Default Template',
  'new_budget_calculation': 'New Budget Calculation',
  'follows_income': 'Follows Income',
  'follows_income_2': 'Follows Income',
  'from_income': 'From Income',
  'reminders': 'Reminders',
  'daily_tracking_reminder': 'Daily Tracking Reminder',
  'reminder_time': 'Reminder Time',
  'end_period_reminder': 'End Period Reminder',
  'data': 'Data',
  'data_mode': 'Data Mode',
  'local_device_storage': 'Local Device Storage',
  'download_data': 'Download Data',
  'online_sync': 'Online Sync',
  'not_connected': 'Not Connected',
  'financial_statistics': 'Financial Statistics',
  'period_summary': 'Period Summary',
  'period_ends_in_days': 'Period Ends In {days} Days',
  'highest_spending_category': 'Highest Spending Category',
  'categories_need_attention': 'Categories Need Attention',
  'most_flexible_category': 'Most Flexible Category',
  'none': 'None',
  'no_recorded_periods_yet': 'No Recorded Periods Yet',
  'no_financial_data_yet': 'No Financial Data Yet',
  'create_a_financial_period_first_the_summary_will_appear_here':
      'Create a financial period first. The summary will appear here.',
  'choose_chart_type': 'Choose Chart Type',
  'line_chart': 'Line Chart',
  'column_chart': 'Column Chart',
  'expense_statistics': 'Expense Statistics',
  'no_expenses_yet': 'No Expenses Yet',
  'expense_records_in_this_period_will_appear_here':
      'Expense records in this period will appear here.',
  'choose_financial_period': 'Choose Financial Period',
  'budget_limit': 'Budget Limit',
  'remaining_money': 'Remaining Money',
  'budget_category_options': 'Budget Category Options',
  'expense_options': 'Expense Options',
  'transaction_options': 'Transaction Options',
  'add_budget_amount': 'Add Budget Amount',
  'reduce_budget_amount': 'Reduce Budget Amount',
  'set_budget_amount': 'Set Budget Amount',
  'reason': 'Reason',
  'write_the_reason_first': 'Write the reason first.',
  'take_from_another_category': 'Take From Another Category',
  'move_to_another_category': 'Move To Another Category',
  'balance_with_another_category': 'Balance With Another Category',
  'do_not_use_another_category': 'Do Not Use Another Category',
  'only_this_category_amount_will_change':
      'Only this category amount will change',
  'change_impact': 'Change Impact',
  'budget_adjusted_successfully': 'Budget adjusted successfully.',
  'add_data': 'Add Data',
  'choose_the_type_of_record_you_want_to_create':
      'Choose the type of record you want to create.',
  'new_budget_category': 'New Budget Category',
  'new_period': 'New Period',
  'edit_budget_category': 'Edit Budget Category',
  'budget_amount': 'Budget Amount',
  'delete_budget_plan': 'Delete Budget Plan?',
  'budget_category_names_cannot_be_duplicated':
      'Budget category names cannot be duplicated.',
  'choose_the_start_and_end_dates_first':
      'Choose the start and end dates first.',
  'the_end_date_must_be_after_the_start_date':
      'The end date must be after the start date.',
  'enter_the_opening_balance_first': 'Enter the opening balance first.',
  'write_the_opening_balance_source_first':
      'Write the opening balance source first.',
  'add_at_least_one_initial_budget_plan':
      'Add at least one initial budget plan.',
  'all_custom_percentages_must_be_greater_than_0':
      'All custom percentages must be greater than 0.',
  'total_percentage_must_be_exactly_100':
      'Total percentage must be exactly 100%.',
  'all_custom_amounts_must_be_greater_than_0':
      'All custom amounts must be greater than 0.',
  'total_amount_cannot_exceed_the_opening_balance':
      'Total amount cannot exceed the opening balance.',
  'total_amount_exceeds_the_opening_balance_of_amount':
      'Total amount exceeds the opening balance of {amount}.',
  'opening_balance_is_not_enough_to_cover_previous_deficit':
      'The opening balance is not enough to cover the previous period deficit.',
  'the_selected_date_overlaps_with_an_existing_period':
      'The selected date overlaps with an existing period.',
  'how_to_split_the_balance': 'How to Split the Balance',
  'budget': 'Budget',
  'add_period': 'Add Period',
  'save_period': 'Save Period',
  'save_financial_period': 'Save Financial Period',
  'saved_financial_period_cannot_be_deleted':
      'A saved financial period cannot be deleted. Make sure the dates, opening balance, and budget plan are correct.',
  'opening_balance': 'Opening Balance',
  'opening_balance_source': 'Opening Balance Source',
  'transfer_remaining_money_from_the_previous_period':
      'Transfer remaining money from the previous period?',
  'cover_previous_period_deficit': 'Cover previous period deficit?',
  'transfer_remaining_money_from_period':
      'Transfer remaining money from {period}?',
  'cover_previous_period_deficit_from_period':
      'Cover the deficit from {period}?',
  'recorded_as_transfer_to_this_period':
      'Recorded as a transfer to this period.',
  'recorded_as_covering_previous_period': 'Recorded as covering that period.',
  'remaining_custom_amount': 'Remaining Custom Amount',
  'initial_budget_plan': 'Initial Budget Plan',
  'allocation_preview': 'Allocation Preview',
  'allocation_formula': 'Allocation Formula',
  'popular_template': 'Popular Template',
  'customize': 'Customize',
  'percentage': 'Percentage',
  'amount_2': 'Amount',
  'rupiah': 'Rupiah',
  'adjust_with_every_income': 'Adjust With Every Income',
  'fixed_amount': 'Fixed Amount',
  'amount_changes_when_income_changes': 'Amount Changes When Income Changes',
  'amount_is_not_recalculated': 'Amount Is Not Recalculated',
  'end': 'End',
  'choose_date': 'Choose Date',
  'choose_date_range': 'Choose Date Range',
  'custom_date_range': 'Custom Date Range',
  'clear_date_range': 'Clear Date Range',
  'filter_by_period': 'Filter By Period',
  'apply': 'Apply',
  'choose_date_2': 'Choose Date',
  'choose_start_and_end_date': 'Choose Start And End Date',
  'start_date_value': 'Start {date}',
  'default_budget': 'Default Budget',
  'review': 'Review',
  'profile': 'Profile',
  'preferences': 'Preferences',
  'period': 'Period',
  'category': 'Category',
  'allocation': 'Allocation',
  'display_name_2': 'Display Name',
  'quick_introduction': 'Quick Introduction',
  'this_name_will_be_used_in_your_profile_and_app_summaries':
      'This name will be used in your profile and app summaries.',
  'write_your_name': 'Write Your Name',
  'choose_app_style': 'Choose App Style',
  'you_can_change_this_later_from_settings':
      'You can change this later from Settings.',
  'color_theme': 'Color Theme',
  'create_your_first_period': 'Create Your First Period',
  'all_money_records_will_go_into_the_period_you_choose':
      'All money records will go into the period you choose.',
  'start_date': 'Start Date',
  'end_date': 'End Date',
  'enter_opening_balance': 'Enter Opening Balance',
  'this_becomes_the_first_income_record_for_that_period':
      'This becomes the first income record for that period.',
  'received_date': 'Received Date',
  'set_up_budget_categories': 'Set Up Budget Categories',
  'use_the_categories_you_track_most_often':
      'Use the categories you track most often.',
  'initial_categories': 'Initial Categories',
  'choose_how_to_split_the_balance': 'Choose How to Split the Balance',
  'dokido_will_calculate_category_amounts_from_your_opening_balance':
      'DokiDo will calculate category amounts from your opening balance.',
  'custom_percentage': 'Custom Percentage',
  'custom_amount': 'Custom Amount',
  'review_before_starting': 'Review Before Starting',
  'if_everything_looks_right_dokido_will_prepare_your_dashboard':
      'If everything looks right, DokiDo will prepare your dashboard.',
  'name': 'Name',
  'balance_source': 'Balance Source',
  'unallocated_balance_2': 'Unallocated Balance',
  'category_name': 'Category Name',
  'enter_percentages_or_amounts_for_each_category':
      'Enter percentages or amounts for each category.',
  'enter_your_display_name_first': 'Enter your display name first.',
  'choose_the_period_start_and_end_dates_first':
      'Choose the period start and end dates first.',
  'the_end_date_must_be_after_the_start_date_2':
      'The end date must be after the start date.',
  'enter_the_opening_balance_first_2': 'Enter the opening balance first.',
  'write_the_opening_balance_source_first_2':
      'Write the opening balance source first.',
  'add_at_least_one_budget_category': 'Add at least one budget category.',
  'budget_category_names_cannot_be_duplicated_2':
      'Budget category names cannot be duplicated.',
  'setup_complete_dokido_is_ready_to_use':
      'Setup complete. DokiDo is ready to use.',
  'there_must_be_at_least_one_budget_category':
      'There must be at least one budget category.',
  'all_percentages_must_be_greater_than_0':
      'All percentages must be greater than 0%.',
  'total_percentage_must_be_exactly_100_2':
      'Total percentage must be exactly 100%.',
  'all_amounts_must_be_greater_than_0': 'All amounts must be greater than 0.',
  'total_amount_cannot_exceed_the_opening_balance_2':
      'Total amount cannot exceed the opening balance.',
  'example_feri': 'Example: Feri',
  'example_main_salary_freelance_bonus':
      'Example: Main Salary, Freelance, Bonus',
  'opening_balance_source_2': 'Opening Balance Source',
  'example_savings_balance_cash_or_this_month_s_money':
      'Example: savings balance, cash, or this month’s money',
  'example_50': 'Example: 50',
  'example_1_000_000': 'Example: 1,000,000',
  'choose_the_currency_and_visual_style_that_feels_comfortable':
      'Choose the currency and visual style that feels comfortable.',
  'fresh_modern_and_closest_to_dokido_s_identity':
      'Fresh, modern, and closest to DokiDo’s identity.',
  'soft_lavender_with_warm_balance':
      'Soft lavender with a balanced warm accent.',
  'cool_blue_clean_and_focused': 'Cool blue, clean, and focused.',
  'bright_blue_for_clear_financial_focus':
      'Bright blue for clear financial focus.',
  'soft_blush_with_a_personal_feel': 'Soft blush with a personal feel.',
  'fresh_mint_with_a_light_sunny_accent':
      'Fresh mint with a light sunny accent.',
  'muted_green_with_soft_paper_tones': 'Muted green with soft paper tones.',
  'deep_green_with_mint_highlights': 'Deep green with fresh mint highlights.',
  'calm_fresh_green_and_comfortable_for_daily_use':
      'Calm, fresh green, and comfortable for daily use.',
  'warm_personal_with_a_strong_accent': 'Warm, personal, with a strong accent.',
  'natural_soft_and_stable': 'Natural, soft, and stable.',
  'minimal_clean_and_calm_for_tidy_tracking':
      'Minimal, clean, and calm for tidy tracking.',
  'bright_clean_with_a_bold_accent': 'Bright, clean, with a bold accent.',
  'recorded_period_count_one': '{count} recorded period',
  'recorded_period_count_many': '{count} recorded periods',
  'expense_record_count_one': '{count} expense record',
  'expense_record_count_many': '{count} expense records',
  'budget_delete_message':
      'Category "{name}" will be removed from this period. This action cannot be undone.',
  'period_delete_message':
      'Period {period} will be deleted with all budget categories, income, expenses, and adjustment history inside it. This action cannot be undone.',
  'category_plan_delete_message':
      'Plan "{name}" will be removed from this period form.',
  'language_indonesian': 'Indonesian',
  'language_english': 'English',
  'currency_idr': 'Indonesian Rupiah',
  'currency_usd': 'US Dollar',
  'theme_teal_balance': 'Teal Balance',
  'theme_fresh_mint': 'Fresh Mint',
  'theme_rose_ledger': 'Rose Ledger',
  'theme_sage_budget': 'Sage Budget',
  'theme_soft_linen': 'Soft Linen',
  'theme_warm_signal': 'Warm Signal',
  'theme_lavender_calm': 'Lavender Calm',
  'theme_coastal_blue': 'Coastal Blue',
  'theme_electric_blue': 'Electric Blue',
  'theme_blush_mauve': 'Blush Mauve',
  'theme_mint_glow': 'Mint Glow',
  'theme_olive_paper': 'Olive Paper',
  'theme_forest_mint': 'Forest Mint',
  'default_daily_needs': 'Daily Needs',
  'legacy_default_basic_needs': 'Basic Needs',
  'default_savings_investment': 'Savings & Investment',
  'default_entertainment': 'Entertainment',
  'default_others': 'Others',
  'formula_priority': 'Priority',
  'formula_balanced': 'Balanced',
  'formula_all_to_one': 'All balance goes to one category',
  'formula_main_then_other':
      'Prioritize the main category, keep the rest for another need',
  'formula_main_and_support': 'One main category and one supporting category',
  'formula_two_important': 'For two categories that are both important',
  'formula_even_two': 'Split evenly between two categories',
  'formula_almost_all_main': 'Almost all balance goes to the main priority',
  'formula_main_flexible_savings': 'Main needs, flexible spending, and savings',
  'formula_main_two_balanced':
      'Main needs with two balanced supporting categories',
  'formula_required_costs_high': 'Useful when required costs are high',
  'formula_required_high_two_funded':
      'High required costs while keeping two other categories funded',
  'formula_lean_essential_high': 'Lean mode when essential costs are high',
  'formula_most_required': 'Most balance goes to required needs',
  'formula_flexible_two_others':
      'More flexible for two categories outside main needs',
  'formula_needs_flexible_entertainment_others':
      'Needs, flexible spending, entertainment, and others',
  'formula_503020_four': '50/30/20 adaptation with two supporting categories',
  'formula_balanced_four': 'More balanced for four categories',
  'formula_large_flexible_two_small':
      'Large flexible category with two smaller balanced categories',
  'formula_high_required_controlled':
      'High required costs while controlling other categories',
  'formula_603010_four': '60/30/10 adaptation with two smaller categories',
  'formula_high_daily_expensive':
      'High essential needs for expensive living costs',
  'formula_prioritize_required': 'Prioritize required costs',
  'formula_very_strict_main': 'Very strict mode for the main priority',
  'formula_even_four': 'Even split across four categories',
  'formula_503020_five': '50/30/20 adaptation for five categories',
  'formula_lighter_main': 'Lighter main priority',
  'formula_dominant_required_small_reserve':
      'Dominant required costs with small reserves',
  'formula_lean_five': 'Lean mode for five categories',
  'formula_gradual_priority': 'Gradual priority ladder',
  'formula_first_larger_rest_even':
      'The first category gets more, the rest is split evenly',
  'formula_even_categories': 'Split evenly across {count} categories',
  'weekday_mon': 'Mon',
  'weekday_tue': 'Tue',
  'weekday_wed': 'Wed',
  'weekday_thu': 'Thu',
  'weekday_fri': 'Fri',
  'weekday_sat': 'Sat',
  'weekday_sun': 'Sun',
  'month_short_1': 'Jan',
  'month_short_2': 'Feb',
  'month_short_3': 'Mar',
  'month_short_4': 'Apr',
  'month_short_5': 'May',
  'month_short_6': 'Jun',
  'month_short_7': 'Jul',
  'month_short_8': 'Aug',
  'month_short_9': 'Sep',
  'month_short_10': 'Oct',
  'month_short_11': 'Nov',
  'month_short_12': 'Dec',
  'month_long_1': 'January',
  'month_long_2': 'February',
  'month_long_3': 'March',
  'month_long_4': 'April',
  'month_long_5': 'May',
  'month_long_6': 'June',
  'month_long_7': 'July',
  'month_long_8': 'August',
  'month_long_9': 'September',
  'month_long_10': 'October',
  'month_long_11': 'November',
  'month_long_12': 'December',
  'error_budget_negative': 'Budget amount cannot be less than zero.',
  'error_source_budget_insufficient':
      'The source budget amount is insufficient.',
  'error_budget_has_history': 'The budget already has history.',
  'error_period_end_before_start':
      'The period end date must be after the start date.',
  'error_period_overlap': 'The selected dates overlap with another period.',
  'transfer_to_period': 'Transfer to period {period}',
  'transfer_from_period': 'Transfer from period {period}',
  'covered_by_period': 'Covered by period {period}',
  'covering_period': 'Covering period {period}',
  'choose': 'Choose',
  'change': 'Change',
  'create': 'Create',
  'set': 'Set',
  'restore': 'Restore',
  'continue': 'Continue',
  'data_and_storage': 'Data & Storage',
  'local_backup': 'Local Backup',
  'backup_storage': 'Backup Storage',
  'backup_location': 'Backup Location',
  'backup_location_not_selected': 'No folder selected',
  'backup_password': 'Backup Password',
  'backup_password_hint': 'At least 8 characters',
  'backup_password_configured': 'Password is configured',
  'backup_password_missing_description': 'No backup password configured',
  'confirm_backup_password': 'Confirm Password',
  'repeat_backup_password': 'Repeat the backup password',
  'create_backup_password': 'Create Backup Password',
  'enter_backup_password': 'Enter Backup Password',
  'save_password': 'Save Password',
  'backup_password_saved': 'Backup password saved successfully.',
  'backup_password_recovery_warning':
      'Keep this password safe. The backup cannot be restored if you forget it.',
  'backup_password_too_short':
      'The backup password must contain at least 8 characters.',
  'backup_passwords_do_not_match': 'The password confirmation does not match.',
  'backup_password_or_file_invalid':
      'The password is incorrect or the backup file cannot be read.',
  'backup_file_invalid': 'This is not a valid DokiDo backup file.',
  'backup_password_not_configured':
      'Create a backup password before continuing.',
  'backup_credential_mismatch':
      'The backup key does not match. Configure the backup password again.',
  'backup_folder_not_configured': 'Choose a backup location first.',
  'backup_settings_unavailable': 'Backup settings are not available yet.',
  'backup_operation_failed': 'The backup operation could not be completed.',
  'backup_operation_failed_with_reason': 'Backup failed: {reason}',
  'automatic_backup': 'Automatic Backup',
  'backup_frequency': 'Backup Frequency',
  'backup_frequency_off': 'Off',
  'backup_frequency_daily': 'Daily',
  'backup_frequency_weekly': 'Weekly',
  'backup_frequency_monthly': 'Monthly',
  'automatic_backup_updated': 'Automatic backup schedule updated.',
  'backup_actions': 'Backup Actions',
  'backup_now': 'Backup Now',
  'backup_now_description': 'Create the latest copy in the backup folder.',
  'restore_latest_backup': 'Restore Latest Backup',
  'restore_latest_backup_description':
      'Use the latest copy from the backup folder.',
  'choose_another_backup_file': 'Choose Another Backup File',
  'choose_another_backup_file_description':
      'Restore a .dokido file from another location.',
  'processing_backup': 'Processing data securely...',
  'backup_ready': 'Backup Is Ready',
  'backup_not_configured': 'Backup Is Not Configured',
  'no_backup_yet': 'No backup has been created',
  'last_backup_value': 'Last backup {date}, {time}',
  'backup_created_successfully': 'The latest backup was created.',
  'latest_backup_not_found': 'The latest backup file was not found.',
  'restore_preview': 'Restore Preview',
  'backup_file': 'Backup File',
  'backup_created_at': 'Created At',
  'financial_periods': 'Financial Periods',
  'transactions': 'Transactions',
  'restore_replaces_current_data_warning':
      'All current financial data will be replaced. Your PIN and App Lock settings will be preserved.',
  'backup_restored_successfully': 'DokiDo data was restored successfully.',
  'change_display_name': 'Change Display Name',
  'display_name_hint': 'Enter the name you want to display',
  'display_name_required': 'A display name is required.',
  'general_info': 'General Information',
  'terms_and_conditions': 'Terms & Conditions',
  'privacy_policy': 'Privacy Policy',
  'version': 'Version',
  'powered_by_niskala': 'Powered by Niskala.dev',
  'terms_and_conditions_content':
      'Last updated: July 2026\n\n'
      'DokiDo is a personal finance tracking application that works locally on the device. By using DokiDo, users remain responsible for the accuracy of recorded data and financial decisions based on that data.\n\n'
      'DokiDo does not provide banking, investment, tax, or professional financial advisory services. Application calculations assist with tracking and planning but should still be reviewed by the user.\n\n'
      'Users are responsible for protecting their device, application PIN, backup password, and backup files. A backup cannot be restored if its password is forgotten.\n\n'
      'Features and data structures may change during beta. Niskala.dev works to maintain application reliability, but users should still create backups regularly.',
  'privacy_policy_content':
      'Last updated: July 2026\n\n'
      'DokiDo is designed as an offline application. Primary financial data is stored encrypted on the device and is not sent to DokiDo servers.\n\n'
      'Notification permission is used for selected transaction reminders and financial alerts. Backup folder access is granted through the Android folder picker and only applies to the folder approved by the user.\n\n'
      'Backup files are encrypted with the backup password. If users save files to a cloud service or share them, those files are governed by the destination service policies.\n\n'
      'DokiDo does not access raw biometric data. Biometric verification is performed by the device operating system.',
  'notifications': 'Notifications',
  'mark_all_as_read': 'Mark All as Read',
  'unread': 'Unread',
  'notifications_could_not_be_loaded': 'Notifications could not be loaded yet.',
  'no_notifications_yet': 'There are no notifications yet.',
  'no_unread_notifications': 'All notifications have been read.',
  'delete_notification': 'Delete Notification?',
  'delete_notification_description':
      'This notification will be removed from DokiDo.',
  'record_now': 'Record Now',
  'view_budget': 'View Budget',
  'fix': 'Fix',
  'view_period': 'View Period',
  'notification_recurring_title': '{title} Needs to Be Recorded',
  'notification_recurring_body': '{amount} is scheduled for {date}.',
  'notification_recurring_category_body':
      '{amount} is scheduled for {date} from {category}.',
  'notification_budget_warning_title': 'Budget Is Almost Used Up',
  'notification_budget_warning_body':
      '{category} has reached {percent}% usage.',
  'notification_budget_exceeded_title': 'Budget Exceeded',
  'notification_budget_exceeded_body':
      '{category} has reached {percent}% of its budget limit.',
  'notification_backup_failed_title': 'Automatic Backup Failed',
  'notification_backup_failed_body':
      'The backup folder cannot be accessed. Choose the backup location again.',
  'notification_period_ending_title': 'Period Ending Soon',
  'notification_period_ending_today_body': 'Period {period} ends today.',
  'notification_period_ending_one_day_body': 'Period {period} ends in 1 day.',
  'notification_period_ending_many_days_body':
      'Period {period} ends in {days} days.',
  'financial_alert_notification_channel': 'Financial Alerts',
  'financial_alert_notification_channel_description':
      'DokiDo budget, period, and backup alerts.',
  'private_notification_title': 'DokiDo Notification',
  'private_notification_body': 'Open DokiDo to view the latest notification.',
};
