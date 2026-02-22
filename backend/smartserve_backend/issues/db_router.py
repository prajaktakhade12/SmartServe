class IssuesRouter:
    """
    A router to control all database operations on issue-related models.
    """

    route_app_labels = {'issues'}

    def db_for_read(self, model, **hints):
        if model._meta.model_name in ['issue', 'feedback', 'notification']:
            return 'issues_db'
        return None

    def db_for_write(self, model, **hints):
        if model._meta.model_name in ['issue', 'feedback', 'notification']:
            return 'issues_db'
        return None

    def allow_relation(self, obj1, obj2, **hints):
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if model_name in ['issue', 'feedback', 'notification']:
            return db == 'issues_db'
        return db == 'default'
