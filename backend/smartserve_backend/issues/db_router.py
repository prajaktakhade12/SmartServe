class IssuesRouter:
    def db_for_read(self, model, **hints):
        if model._meta.model_name == 'issue':
            return 'issues_db'
        if model._meta.model_name == 'notification':
            return 'notifications_db'
        return 'default'

    def db_for_write(self, model, **hints):
        if model._meta.model_name == 'issue':
            return 'issues_db'
        if model._meta.model_name == 'notification':
            return 'notifications_db'
        return 'default'

    def allow_relation(self, obj1, obj2, **hints):
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if model_name == 'issue':
            return db == 'issues_db'
        if model_name == 'notification':
            return db == 'notifications_db'
        return db == 'default'