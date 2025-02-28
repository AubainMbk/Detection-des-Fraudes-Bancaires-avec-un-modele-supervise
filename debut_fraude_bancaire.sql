
-- Créons la base de donnée fraude_bancaire
CREATE DATABASE fraude_bancaire;


-- drop table fraude_bancaire.Clients;
-- drop table fraude_bancaire.Comptes;
-- drop table fraude_bancaire.CartesBancaires;

-- Créons la table Clients

CREATE TABLE fraude_bancaire.Clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prénom VARCHAR(50) NOT NULL,
    âge INT CHECK (âge >= 18),
    sexe ENUM('Homme', 'Femme', 'Autre') NOT NULL,
    pays VARCHAR(50) NOT NULL,
    revenu_annuel DECIMAL(10,2) CHECK (revenu_annuel >= 0)
);

-- Créons la table Comptes

CREATE TABLE fraude_bancaire.Comptes (
    compte_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    type_compte ENUM('Courant', 'Épargne', 'Crédit') NOT NULL,
    solde DECIMAL(15,2) CHECK (solde >= 0),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_client_id (client_id)
);

-- Créeons un trigger pour s'assurer à chaque fois que chaque carte bancaire est associée à un ompte bancaire
DELIMITER //
CREATE TRIGGER fraude_bancaire.check_compte_exists
BEFORE INSERT ON fraude_bancaire.CartesBancaires
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fraude_bancaire.Comptes WHERE compte_id = NEW.compte_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : compte_id inexistant !';
    END IF;
END;
//
DELIMITER ;


-- Créoons la table transaction et veuillons à faire un partitionnement qui nous permettra de facilement manipuler nos données
CREATE TABLE fraude_bancaire.Transactions (
    transaction_id INT NOT NULL AUTO_INCREMENT,
    compte_id INT NOT NULL,
    montant DECIMAL(10,2) NOT NULL,
    date_transaction DATE NOT NULL,
    type_transaction ENUM('Retrait', 'Dépôt', 'Virement', 'Paiement') NOT NULL,
    lieu VARCHAR(100),
    fraude BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (transaction_id, date_transaction)  -- Ajout de date_transaction
) PARTITION BY RANGE (YEAR(date_transaction) * 100 + MONTH(date_transaction)) (
    PARTITION transactions_2024_01 VALUES LESS THAN (202402),
    PARTITION transactions_2024_02 VALUES LESS THAN (202403),
    PARTITION transactions_2024_03 VALUES LESS THAN (202404),
    PARTITION transactions_2024_04 VALUES LESS THAN (202405),
    PARTITION transactions_2024_05 VALUES LESS THAN (202406),
    PARTITION transactions_2024_06 VALUES LESS THAN (202407),
    PARTITION transactions_2024_07 VALUES LESS THAN (202408),
    PARTITION transactions_2024_08 VALUES LESS THAN (202409),
    PARTITION transactions_2024_09 VALUES LESS THAN (202410),
    PARTITION transactions_2024_10 VALUES LESS THAN (202411),
    PARTITION transactions_2024_11 VALUES LESS THAN (202412),
    PARTITION transactions_2024_12 VALUES LESS THAN (202501)
);

-- Evidemment nous créeons un trigger qui nous permettra de nous assurer que chaque fraude dans historiqueFraude est associée à une transaction 
DELIMITER //
CREATE TRIGGER fraude_bancaire.check_transaction_exists
BEFORE INSERT ON fraude_bancaire.HistoriqueFraudes
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fraude_bancaire.Transactions WHERE transaction_id = NEW.transaction_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : transaction_id inexistant !';
    END IF;
END;
//
DELIMITER ;



-- Créons la table CarteBancaire
CREATE TABLE fraude_bancaire.CartesBancaires (
    carte_id INT AUTO_INCREMENT PRIMARY KEY,
    compte_id INT NOT NULL,
    type_carte ENUM('Débit', 'Crédit', 'Prépayée') NOT NULL,
    date_expiration DATE NOT NULL,
    code_securite CHAR(3) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    INDEX idx_compte_id (compte_id)
);


-- Créons la table HistoriqueFraudes
CREATE TABLE fraude_bancaire.HistoriqueFraudes (
    fraude_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    raison VARCHAR(255) NOT NULL,
    date_detection TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- Optimisation des requêtes cherchant tous les comptes d'un client donné ( Aulieu de rechercher dans toute la table , la base trouvera immmédiatement le compte souhaité grace à son indice;)
CREATE INDEX idx_client_id ON fraude_bancaire.Comptes(client_id);

-- Pareil pour les transactions d'un compte bancaire
CREATE INDEX idx_compte_id ON Transactions(compte_id);

-- pareil, accélère les recherche de transactions basées sur la date
CREATE INDEX idx_date_transaction ON Transactions(date_transaction);

-- pareil, accélère les recherche de transactions basées sur le type de transaction 
CREATE INDEX idx_type_transaction ON Transactions(type_transaction);


-- Pour finir, améliorons notre base de données plus rapide et plus efficace pour les analyses mensuelles des transactions !
ALTER TABLE fraude_bancaire.Transactions
PARTITION BY RANGE (YEAR(date_transaction) * 100 + MONTH(date_transaction)) (
    PARTITION transactions_2024_01 VALUES LESS THAN (202402),
    PARTITION transactions_2024_02 VALUES LESS THAN (202403),
    PARTITION transactions_2024_03 VALUES LESS THAN (202404),
    PARTITION transactions_2024_04 VALUES LESS THAN (202405),
    PARTITION transactions_2024_05 VALUES LESS THAN (202406),
    PARTITION transactions_2024_06 VALUES LESS THAN (202407),
    PARTITION transactions_2024_07 VALUES LESS THAN (202408),
    PARTITION transactions_2024_08 VALUES LESS THAN (202409),
    PARTITION transactions_2024_09 VALUES LESS THAN (202410),
    PARTITION transactions_2024_10 VALUES LESS THAN (202411),
    PARTITION transactions_2024_11 VALUES LESS THAN (202412),
    PARTITION transactions_2024_12 VALUES LESS THAN (202501)
);


-- INSERONS DES DONNEES FICITVES POUR TAFFER

-- Exemple d'insertion dynamique pour générer des données fictives
INSERT INTO fraude_bancaire.Clients (nom, prénom, âge, sexe, pays, revenu_annuel)
SELECT 
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Dupont'
        ELSE 'Martin' 
    END AS nom,
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Pierre'
        ELSE 'Sophie' 
    END AS prénom,
    FLOOR(RAND() * (70 - 18 + 1)) + 18 AS âge,  -- Générer un âge entre 18 et 70
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Homme'
        ELSE 'Femme'
    END AS sexe,
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'France'
        WHEN FLOOR(RAND() * 3) = 1 THEN 'Belgique'
        ELSE 'Canada'
    END AS pays,
    FLOOR(RAND() * (100000 - 30000 + 1)) + 30000 AS revenu_annuel -- Générer un revenu entre 30 000 et 100 000
FROM
    (SELECT 1 FROM dual LIMIT 1000) AS temp;  -- Générer 1000 lignes


-- Exemple d'insertion dynamique pour générer 1000 clients fictifs
-- Exemple d'insertion dynamique pour générer 1000 clients fictifs
INSERT INTO fraude_bancaire.Clients (nom, prénom, âge, sexe, pays, revenu_annuel)
SELECT 
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Dupont'
        ELSE 'Martin' 
    END AS nom,
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Pierre'
        ELSE 'Sophie' 
    END AS prénom,
    FLOOR(RAND() * (70 - 18 + 1)) + 18 AS âge,  -- Générer un âge entre 18 et 70
    CASE 
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Homme'
        ELSE 'Femme'
    END AS sexe,
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'France'
        WHEN FLOOR(RAND() * 3) = 1 THEN 'Belgique'
        ELSE 'Canada'
    END AS pays,
    FLOOR(RAND() * (100000 - 30000 + 1)) + 30000 AS revenu_annuel -- Générer un revenu entre 30 000 et 100 000
FROM
    information_schema.columns AS c1
LIMIT 500;  -- Générer 1000 lignes



    
    -- je m'insère également
INSERT INTO fraude_bancaire.Clients (nom, prénom, âge, sexe, pays, revenu_annuel)
VALUES ('Mbokou', 'Aubain', 26, 'Homme', 'France', 18000.00);

select*
from fraude_bancaire.Clients;

-- Ajoutons en quelques uns ( on aura au total 537 lignes)
INSERT INTO fraude_bancaire.Clients (nom, prénom, âge, sexe, pays, revenu_annuel)
VALUES
('Martin', 'Sophie', 42, 'Femme', 'Belgique', 55000.00),
('Lemoine', 'Luc', 28, 'Homme', 'Canada', 38000.00),
('Durand', 'Claire', 31, 'Femme', 'France', 60000.00),
('Girard', 'Marc', 55, 'Homme', 'Allemagne', 70000.00),
('Nguyen', 'Linh', 40, 'Femme', 'Vietnam', 50000.00),
('Boulanger', 'Lucas', 29, 'Homme', 'France', 40000.00),
('Rousseau', 'Juliette', 50, 'Femme', 'Canada', 75000.00),
('Fournier', 'Antoine', 45, 'Homme', 'Belgique', 68000.00),
('Blanc', 'Marie', 38, 'Femme', 'Suisse', 52000.00),
('Meyer', 'David', 33, 'Homme', 'Allemagne', 59000.00),
('Lemoine', 'Sophie', 27, 'Femme', 'France', 30000.00),
('Schmitt', 'Julien', 60, 'Homme', 'Luxembourg', 80000.00),
('Tremblay', 'Nathalie', 48, 'Femme', 'Canada', 70000.00),
('Benoit', 'François', 62, 'Homme', 'France', 40000.00),
('Klein', 'Eva', 53, 'Femme', 'Allemagne', 95000.00),
('Muller', 'Jean', 59, 'Homme', 'France', 71000.00),
('Leclerc', 'Camille', 36, 'Femme', 'Belgique', 54000.00),
('Dufresne', 'Pierre', 30, 'Homme', 'Canada', 40000.00),
('Bernard', 'Alice', 39, 'Femme', 'Suisse', 50000.00),
('Dubois', 'Hélène', 43, 'Femme', 'France', 48000.00),
('Smith', 'John', 45, 'Homme', 'USA', 80000.00),
('Johnson', 'Emma', 36, 'Femme', 'USA', 75000.00),
('Williams', 'Olivia', 40, 'Femme', 'UK', 71000.00),
('Brown', 'Liam', 38, 'Homme', 'Australia', 67000.00),
('Jones', 'Noah', 28, 'Homme', 'USA', 45000.00),
('Davis', 'Sophia', 55, 'Femme', 'Canada', 90000.00),
('Moore', 'Isabella', 60, 'Femme', 'USA', 95000.00),
('Taylor', 'James', 50, 'Homme', 'Germany', 85000.00),
('Anderson', 'Ava', 31, 'Femme', 'Canada', 65000.00),
('Thomas', 'Mason', 33, 'Homme', 'UK', 62000.00),
('Sullivan', 'Lucas', 32, 'Homme', 'Australia', 58000.00),
('King', 'Grace', 35, 'Femme', 'UK', 51000.00),
('Scott', 'Jack', 48, 'Homme', 'USA', 78000.00),
('Green', 'Chloe', 30, 'Femme', 'Canada', 56000.00),
('Adams', 'Michael', 44, 'Homme', 'Suisse', 67000.00);

-- TRUNCATE TABLE fraude_bancaire.Comptes;

-- Exemple d'insertion dynamique pour générer 1000 comptes fictifs
INSERT INTO fraude_bancaire.Comptes (client_id, type_compte, solde, date_creation)
SELECT 
    FLOOR(RAND() * 1000) + 1 AS client_id,  -- Associer un client_id aléatoire (1 à 1000)
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'Courant'
        WHEN FLOOR(RAND() * 3) = 1 THEN 'Épargne'
        ELSE 'Crédit'
    END AS type_compte,
    FLOOR(RAND() * (10000 - 1000 + 1)) + 1000 AS solde,  -- Solde entre 1000 et 10000
    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 365) DAY) AS date_creation
FROM
    information_schema.columns AS c1
LIMIT 537;




-- Exemple d'insertion dynamique pour générer 1000 transactions fictives
INSERT INTO fraude_bancaire.Transactions (compte_id, montant, date_transaction, type_transaction, lieu, fraude)
SELECT 
    FLOOR(RAND() * 1000) + 1 AS compte_id,  -- Associer un compte_id aléatoire (1 à 1000)
    ROUND(RAND() * (5000 - 10 + 1)) + 10 AS montant,  -- Montant entre 10 et 5000
    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 365) DAY) AS date_transaction,  -- Date aléatoire en 2024
    CASE 
        WHEN FLOOR(RAND() * 4) = 0 THEN 'Retrait'
        WHEN FLOOR(RAND() * 4) = 1 THEN 'Dépôt'
        WHEN FLOOR(RAND() * 4) = 2 THEN 'Virement'
        ELSE 'Paiement'
    END AS type_transaction,
    CASE 
        WHEN FLOOR(RAND() * 5) = 0 THEN 'Paris'
        WHEN FLOOR(RAND() * 5) = 1 THEN 'Lyon'
        WHEN FLOOR(RAND() * 5) = 2 THEN 'Marseille'
        WHEN FLOOR(RAND() * 5) = 3 THEN 'Berlin'
        ELSE 'Bruxelles'
    END AS lieu,
    CASE 
        WHEN FLOOR(RAND() * 10) = 0 THEN TRUE  -- 10% de chance d'être frauduleuse
        ELSE FALSE
    END AS fraude
FROM
    information_schema.columns AS c1
LIMIT 1000;

-- Exemple d'insertion dynamique pour générer 1000 cartes fictives
INSERT INTO fraude_bancaire.CartesBancaires (compte_id, type_carte, date_expiration, code_securite, active)
SELECT 
    c.compte_id,
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'Débit'
        WHEN FLOOR(RAND() * 3) = 1 THEN 'Crédit'
        ELSE 'Prépayée'
    END AS type_carte,
    DATE_ADD(CURRENT_DATE, INTERVAL FLOOR(RAND() * 5) + 1 YEAR) AS date_expiration,
    LPAD(FLOOR(RAND() * 1000), 3, '0') AS code_securite,
    TRUE AS active
FROM fraude_bancaire.Comptes c
ORDER BY RAND()
LIMIT 537;



-- insertion dynamique pour générer l'historique des fraudes
INSERT INTO fraude_bancaire.HistoriqueFraudes (transaction_id, raison, date_detection)
SELECT 
    t.transaction_id,
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'Montant anormalement élevé'
        WHEN FLOOR(RAND() * 3) = 1 THEN 'Lieu suspect'
        ELSE 'Fréquence inhabituelle'
    END AS raison,
    t.date_transaction 
FROM fraude_bancaire.Transactions t
WHERE t.fraude = TRUE;


SELECT * FROM Comptes;
SELECT * FROM Transactions WHERE fraude = TRUE;
SELECT * FROM Clients;
SELECT * FROM cartesbancaires;
SELECT * FROM historiquefraudes;

-- Mes tables ont bien été créées , passons à la 2ème étape : l'analyse de données via des réquètes

-- Transactions suspectes par montant
   -- On filtre les transactions qui dépassent de 3 écarts-types la moyenne (règle statistique classique).
SELECT 
    t.transaction_id,
    t.compte_id,
    c.client_id,
    c.nom,
    c.prénom,
    t.montant,
    t.date_transaction
FROM fraude_bancaire.Transactions t
JOIN fraude_bancaire.Comptes co ON t.compte_id = co.compte_id
JOIN fraude_bancaire.Clients c ON co.client_id = c.client_id
WHERE t.montant > (
    SELECT AVG(montant) + 3 * STD(montant) FROM fraude_bancaire.Transactions
)
ORDER BY t.montant DESC;

	-- Parfait , nous n'avons pas de transaction suspecte vu sous cet angle , continuons

-- Transactions réalisées à des lieux différents en peu de temps
	-- L’utilisation de fonctions analytiques (LAG) permet de comparer la localisation et le moment de transactions successives sur un même compte pour repérer des déplacements improbables.
WITH TransacTemps AS (
    SELECT 
        t.transaction_id,
        t.compte_id,
        t.lieu,
        t.date_transaction,
        LAG(t.lieu) OVER (PARTITION BY t.compte_id ORDER BY t.date_transaction) AS lieu_precedent,
        LAG(t.date_transaction) OVER (PARTITION BY t.compte_id ORDER BY t.date_transaction) AS date_precedente
    FROM fraude_bancaire.Transactions t
)
SELECT 
    transaction_id,
    compte_id,
    lieu,
    lieu_precedent,
    date_transaction,
    date_precedente
FROM TransacTemps
WHERE 
    lieu <> lieu_precedent 
    AND TIMESTAMPDIFF(MINUTE, date_precedente, date_transaction) < 60;

-- Nous avons trouvé les transactions : transaction_id = 640 et = 883 sont réalisées à des lieux différents et en peu de temps : c'est suspect
-- Continuons notre analyse

-- Série de transactions rapides sur un même compte
	-- Détecter les comptes qui réalisent un grand nombre de transactions en peu de temps, ce qui peut indiquer un comportement frauduleux
SELECT 
    compte_id, 
    COUNT(transaction_id) AS nombre_transactions,
    MIN(date_transaction) AS debut,
    MAX(date_transaction) AS fin
FROM fraude_bancaire.Transactions
WHERE date_transaction BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY compte_id
HAVING COUNT(transaction_id) > 10;

-- Nous n'avons rien trouvé
-- Continuons 

-- Utilisation suspecte d’une carte expirée
	-- Détecter si une transaction a été réalisée avec une carte dont la date d'expiration est antérieure à la date de transaction.
SELECT 
    cb.carte_id, 
    cb.compte_id, 
    cb.date_expiration, 
    t.transaction_id, 
    t.date_transaction
FROM fraude_bancaire.CartesBancaires cb
JOIN fraude_bancaire.Transactions t ON cb.compte_id = t.compte_id
WHERE cb.date_expiration < t.date_transaction;

-- Nous n'avons rien trouvé
-- Continuons

-- Clients avec plusieurs comptes et virements internes
	-- Identifier les clients possédant plusieurs comptes et réalisant des virements entre eux, ce qui peut être un indicateur de blanchiment d'argent.
SELECT 
    c.client_id, 
    c.nom, 
    c.prénom, 
    COUNT(DISTINCT co.compte_id) AS nb_comptes
FROM fraude_bancaire.Clients c
JOIN fraude_bancaire.Comptes co ON c.client_id = co.client_id
JOIN fraude_bancaire.Transactions t ON co.compte_id = t.compte_id
WHERE t.type_transaction = 'Virement'
GROUP BY c.client_id, c.nom, c.prénom
HAVING COUNT(DISTINCT co.compte_id) > 3;

-- Nous n'avons rien trouvé
-- Continuons

-- Transactions anormales par rapport au revenu du client
	-- Comparer le montant d'une transaction avec le revenu annuel du client pour repérer des transactions disproportionnées.
SELECT 
    t.transaction_id, 
    t.compte_id, 
    c.client_id, 
    c.nom, 
    c.prénom, 
    t.montant, 
    c.revenu_annuel
FROM fraude_bancaire.Transactions t
JOIN fraude_bancaire.Comptes co ON t.compte_id = co.compte_id
JOIN fraude_bancaire.Clients c ON co.client_id = c.client_id
WHERE t.montant > (c.revenu_annuel / 2);

-- Nous n'avons rien trouvé

-- A présent , écrivons de nombreuses réquètes pour s'exercer

-- Transactions frauduleuses récentes avec détails clients
SELECT 
    c.nom, 
    c.prénom, 
    t.montant, 
    t.lieu, 
    h.raison,
    t.date_transaction
FROM 
    fraude_bancaire.Transactions t
JOIN 
    HistoriqueFraudes h ON t.transaction_id = h.transaction_id
JOIN 
    Comptes co ON t.compte_id = co.compte_id
JOIN 
    Clients c ON co.client_id = c.client_id
WHERE 
    t.fraude = TRUE
    AND t.date_transaction >= '2024-03-01'
ORDER BY 
    t.montant DESC
LIMIT 20;


-- Cartes de crédit associées à des comptes frauduleux
SELECT 
    cb.type_carte, 
    COUNT(DISTINCT t.transaction_id) AS nb_fraudes,
    AVG(t.montant) AS montant_moyen
FROM 
    CartesBancaires cb
JOIN 
    Transactions t ON cb.compte_id = t.compte_id
WHERE 
    t.fraude = TRUE
GROUP BY 
    cb.type_carte
HAVING 
    nb_fraudes > 3;

-- Détection d'écart soudain de comportement
WITH ComportementClient AS (
    SELECT 
        co.client_id,
        AVG(t.montant) AS montant_moyen,
        COUNT(t.transaction_id) AS freq_transactions
    FROM 
        Transactions t
    JOIN 
        Comptes co ON t.compte_id = co.compte_id
    WHERE 
        t.date_transaction BETWEEN '2024-01-01' AND '2024-03-31'
    GROUP BY 
        co.client_id
)

SELECT 
    c.nom,
    c.prénom,
    t.montant,
    (t.montant - cc.montant_moyen) AS ecart_montant,
    t.date_transaction
FROM 
    Transactions t
JOIN 
    Comptes co ON t.compte_id = co.compte_id
JOIN 
    Clients c ON co.client_id = c.client_id
JOIN 
    ComportementClient cc ON co.client_id = cc.client_id
WHERE 
    t.montant > cc.montant_moyen * 5
    AND t.date_transaction > '2024-04-01';

    
    -- Détection de multi-fraudes sur mêmes coordonnées bancaires
    SELECT 
    cb.carte_id,
    cb.code_securite,
    COUNT(h.fraude_id) AS nb_fraudes,
    GROUP_CONCAT(DISTINCT h.raison) AS motifs
FROM 
    CartesBancaires cb
JOIN 
    Transactions t ON cb.compte_id = t.compte_id
JOIN 
    HistoriqueFraudes h ON t.transaction_id = h.transaction_id
WHERE 
    cb.date_expiration > CURDATE()
GROUP BY 
    cb.carte_id, cb.code_securite
HAVING 
    nb_fraudes > 2
ORDER BY 
    nb_fraudes DESC;


-- Rapport mensuel complet avec indicateurs de risque
SELECT 
    c.client_id,
    c.nom,
    c.prénom,
    c.revenu_annuel,
    SUM(t.montant) AS total_transactions_mois,
    SUM(CASE WHEN t.fraude THEN t.montant ELSE 0 END) AS montant_fraude,
    ROUND(SUM(t.fraude)/COUNT(*)*100, 2) AS ratio_risk,
    CASE 
        WHEN SUM(t.fraude)/COUNT(*) > 0.3 THEN 'ALERTE ROUGE'
        WHEN SUM(t.fraude)/COUNT(*) > 0.1 THEN 'ALERTE ORANGE'
        ELSE 'NORMAL'
    END AS niveau_alerte
FROM 
    Clients c
JOIN 
    Comptes co ON c.client_id = co.client_id
JOIN 
    Transactions t ON co.compte_id = t.compte_id
WHERE 
    t.date_transaction BETWEEN '2024-05-01' AND '2024-05-31'
GROUP BY 
    c.client_id
HAVING 
    montant_fraude > 1000
ORDER BY 
    ratio_risk DESC;



-- Passons à présent à la DÉTECTION DE FRAUDE AVEC L'IA 

-- Extraction des données pour entraîner notre modèle.
SELECT 
    t.transaction_id, c.client_id, c.âge, c.revenu_annuel, 
    co.type_compte, t.montant, t.type_transaction, t.lieu, 
    t.date_transaction, t.fraude
FROM Transactions t
JOIN Comptes co ON t.compte_id = co.compte_id
JOIN Clients c ON co.client_id = c.client_id;


