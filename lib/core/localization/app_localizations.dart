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
    if (language == AppLanguage.id) return '$count periode tercatat';
    return '$count recorded ${count == 1 ? 'period' : 'periods'}';
  }

  String expenseRecordCount(int count) {
    if (language == AppLanguage.id) return '$count catatan uang keluar';
    return '$count expense ${count == 1 ? 'record' : 'records'}';
  }

  String budgetDeleteMessage(String categoryName) {
    if (language == AppLanguage.id) {
      return 'Kategori "$categoryName" akan dihapus dari periode ini. Aksi ini tidak bisa dibatalkan.';
    }
    return 'Category "$categoryName" will be removed from this period. This action cannot be undone.';
  }

  String periodDeleteMessage(String periodLabel) {
    if (language == AppLanguage.id) {
      return 'Periode $periodLabel akan dihapus bersama seluruh kategori anggaran, uang masuk, uang keluar, dan riwayat perubahan di dalamnya. Aksi ini tidak bisa dibatalkan.';
    }
    return 'Period $periodLabel will be deleted with all budget categories, income, expenses, and adjustment history inside it. This action cannot be undone.';
  }

  String categoryDeleteMessage(String name) {
    if (language == AppLanguage.id) {
      return 'Rencana "$name" akan dihapus dari form periode ini.';
    }
    return 'Plan "$name" will be removed from this period form.';
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
  'powered_by_feri': 'Powered by Feri',
  'transaction_templates': 'Template Transaksi',
  'transaction_templates_settings_value': 'Template Cepat Dan Berulang',
  'quick_templates': 'Template Cepat',
  'quick_template': 'Template Cepat',
  'recurring_transactions': 'Transaksi Berulang',
  'needs_to_be_recorded_today': 'Perlu Dicatat Hari Ini',
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
};

const _en = <String, String>{
  'failed_to_load_settings_error': 'Failed to load settings: {error}',
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
  'powered_by_feri': 'Powered by Feri',
  'transaction_templates': 'Transaction Templates',
  'transaction_templates_settings_value': 'Quick And Recurring Templates',
  'quick_templates': 'Quick Templates',
  'quick_template': 'Quick Template',
  'recurring_transactions': 'Recurring Transactions',
  'needs_to_be_recorded_today': 'Needs To Be Recorded Today',
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
};
