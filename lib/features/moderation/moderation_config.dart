/// ⚙️ Configuration centralisée — UN SEUL endroit à ajuster si schéma différent
class ModerationConfig {
  ModerationConfig._();

  /// Tables de signalements à scanner
  static const List<ReportSource> sources = [
    ReportSource(
      table: 'post_reports',
      contentType: 'post',
      contentTables: ['network_posts', 'social_posts', 'posts'],
      commentTables: [],
    ),
    ReportSource(
      table: 'comment_reports',
      contentType: 'comment',
      contentTables: [],
      commentTables: ['comments', 'social_post_comments'],
    ),
  ];

  /// Alias de colonnes (normalisation tolérante)
  static const statusKeys = ['status', 'state', 'resolution'];
  static const reasonKeys = ['reason', 'report_reason', 'type', 'category'];
  static const detailsKeys = ['details', 'description', 'message'];
  static const targetKeys = ['post_id', 'comment_id', 'content_id', 'target_id'];
  static const reporterKeys = ['reporter_id', 'reported_by', 'user_id', 'created_by'];
  static const authorKeys = ['user_id', 'author_id', 'created_by', 'uid'];

  /// Valeurs considérées comme "déjà traitées" côté source
  static const resolvedValues = [
    'resolved', 'reviewed', 'closed', 'handled', 'dismissed', 'approved',
  ];

  /// Payloads essayés dans l'ordre pour masquer un contenu
  static const takedownPayloads = [
    {'status': 'hidden'},
    {'status': 'removed'},
    {'status': 'deleted'},
    {'deleted': true},
    {'is_hidden': true},
    {'visibility': 'private'},
  ];
}

class ReportSource {
  final String table;
  final String contentType;
  final List<String> contentTables;
  final List<String> commentTables;

  const ReportSource({
    required this.table,
    required this.contentType,
    required this.contentTables,
    required this.commentTables,
  });

  List<String> get targetTables =>
      contentType == 'post' ? contentTables : commentTables;
}
