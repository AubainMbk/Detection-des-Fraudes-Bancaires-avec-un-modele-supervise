# Détection des Fraudes Bancaires avec un modèle supervisé (Python, SQL, Machine Learning, Finance)

## 📌Objectif : Construire un modèle de détection de fraude sur les transactions bancaires.

# 📌 Rapport 

## **1️⃣ Introduction**  

La fraude bancaire est un enjeu majeur dans le domaine financier, nécessitant des méthodes avancées pour identifier les transactions suspectes. L’objectif de ce projet est de développer un modèle de **Machine Learning** permettant de détecter les transactions frauduleuses en exploitant les données transactionnelles et les informations clients.  

---

## **2️⃣ Acquisition et Prétraitement des Données**  

### **2.1 Connexion à la Base de Données MySQL**  
Nous avons extrait les données depuis une base **MySQL** contenant les transactions bancaires et les informations des clients.  

📌 **Requête SQL utilisée :**  
```sql
SELECT
    t.transaction_id, t.compte_id, t.montant, t.date_transaction, t.type_transaction, 
    t.lieu, t.fraude, c.client_id, c.nom, c.prénom, c.âge, c.sexe, c.pays, c.revenu_annuel
FROM Transactions t
JOIN Comptes co ON t.compte_id = co.compte_id
JOIN Clients c ON co.client_id = c.client_id
WHERE t.date_transaction BETWEEN '2024-01-01' AND '2024-12-31';
```

📌 **Données récupérées :**
- Montant de la transaction  
- Type de transaction (Achat, Retrait, etc.)  
- Lieu de la transaction  
- Date et heure  
- Informations client (âge, sexe, pays, revenu annuel)  
- Étiquette de fraude (0 = normal, 1 = fraude)  

---

### **2.2 Prétraitement et Feature Engineering**  

🔹 **Transformation des données** :  
- **Encodage des variables catégorielles** (type de transaction, lieu, sexe) avec `LabelEncoder`.  
- **Ajout de nouvelles features** :
  - `jour_semaine` → Jour de la semaine de la transaction.  
  - `montant_relatif` → Montant par rapport au revenu annuel du client.  
  - `log_montant` → Logarithme du montant pour réduire l’effet des valeurs extrêmes.  

---

## **3️⃣ Entraînement du Modèle de Machine Learning**  

Nous avons utilisé **Random Forest**, un modèle puissant pour la classification, et appliqué **SMOTE** pour équilibrer la classe minoritaire (fraudes).

📌 **Pipeline d’entraînement :**  
1. **Séparation des données** en `X_train, X_test, y_train, y_test`.  
2. **Standardisation** des variables numériques avec `StandardScaler`.  
3. **Sur-échantillonnage** de la classe minoritaire avec `SMOTE`.  
4. **Entraînement du modèle** `RandomForestClassifier(n_estimators=100)`.  

📌 **Évaluation du modèle :**  
- **Matrice de confusion** → Très bonnes performances sur les données de test.  
- **Taux de détection des fraudes élevé** ✅.  
- **Quelques cas non détectés** → Problème d’encodage des nouvelles valeurs non vues pendant l’entraînement.  

---

## **4️⃣ Tests et Cas d’Utilisation**  

Nous avons testé le modèle sur plusieurs transactions :  

### **4.1 Transactions suspectes (frauduleuses) détectées** ✅  
| Montant | Type | Lieu | Âge | Revenu annuel | Détection |
|---------|------|------|----|--------------|-----------|
| 8,000,000,000 € | Retrait | New York | 25 | 10,000 € | ✅ FRAUDE |
| 50,000 € | Achat en ligne | Dubaï | 19 | 8,000 € | ✅ FRAUDE |
| 100,000 € | Virement | Russie | 45 | 15,000 € | ✅ FRAUDE |

### **4.2 Transactions normales (non frauduleuses)** ✅  
| Montant | Type | Lieu | Âge | Revenu annuel | Détection |
|---------|------|------|----|--------------|-----------|
| 50 € | Achat | Paris | 35 | 40,000 € | ✅ NORMAL |
| 200 € | Restaurant | Lyon | 28 | 35,000 € | ✅ NORMAL |
| 1,000 € | Virement | France | 45 | 50,000 € | ✅ NORMAL |

---

## **5️⃣ Problèmes rencontrés et Corrections apportées**  

🔴 **Problème 1 : Valeurs inconnues dans l’encodage (`LabelEncoder`)**  
- **Symptôme** : `ValueError: y contains previously unseen labels` (ex: "Dubaï", "Achat en ligne").  
- **Solution** : Utilisation de `handle_unknown='ignore'` avec `OneHotEncoder` pour gérer les nouvelles valeurs.  

🔴 **Problème 2 : Erreur de Feature Matching**  
- **Symptôme** : `The feature names should match those that were passed during fit`.  
- **Solution** : Assurer que les features d’entraînement et de test sont identiques.  

🔴 **Problème 3 : SMOTE et valeurs manquantes (`NaN`)**  
- **Symptôme** : `ValueError: Input X contains NaN.`  
- **Solution** : Ajout d’un **imputer** pour remplacer les valeurs manquantes.  

---

## **6️⃣ Conclusion et Recommandations**  

✅ **Objectif atteint** : Notre modèle **Random Forest** détecte efficacement les fraudes, avec une **sensibilité élevée**.  
✅ **Le modèle fonctionne bien** en production locale avec des tests unitaires sur plusieurs cas.  

📌 **Recommandations pour aller plus loin** :  
1. **Déploiement de l’API avec Flask** → Permet d’intégrer notre modèle dans une application web.  
2. **Utilisation d’un modèle plus avancé (XGBoost, LightGBM)** pour améliorer la précision.  
3. **Collecte de plus de données** pour renforcer la robustesse du modèle.  
4. **Surveillance en temps réel** avec un **système d’alerte** en cas de fraude détectée.  

---

# **📢 Prochaine étape : Déploiement de l’API 🚀**  
Le prochain objectif sera de **déployer notre modèle via une API Flask** et d’intégrer une interface web pour tester les transactions en temps réel.  


