
import os

DATABASE = os.environ.get("TASKFLOW_DB", "taskflow.db")

# Clé du prestataire de paiement
PAYMENT_API_KEY = os.environ.get("PAYMENT_API_KEY", "")
