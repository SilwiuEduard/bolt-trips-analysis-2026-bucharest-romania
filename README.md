# 🚕 Bolt Analytics: Enterprise ETL Pipeline & Operational Optimization

<p align="center">
  <img src="./images/powerBI_animation.gif" alt="Power BI Dashboard Demo" width="600">
</p>

Choose Language / Alege Limba:

- 🌍 **[English Version](#-english-version)**
- 🇷🇴 **[Versiunea in Romana](#-versiunea-in-romana)**

---

## 🌍 English Version

### 📌 Project Overview

An **end-to-end Data Engineering & Business Intelligence pipeline** analyzing operational and financial performance across the Bolt rideshare platform in Bucharest.

This project covers the complete data lifecycle:

1. **Automated Enterprise Extraction (Python + REST API):** Weekly incremental ingestion and backfill of raw operational data (`orders`, `state_logs`, `drivers`, `vehicles`).
2. **Automated CI/CD Orchestration (GitHub Actions):** Scheduled jobs running weekly in the cloud to execute the full pipeline (Python extraction, BigQuery SQL transformations, and automated data exports).
3. **Private Cloud Storage (Azure Blob Storage - Bronze Layer):** Secure raw JSON/CSV storage isolated from public repositories for privacy and security.
4. **Data Warehousing & SQL Transformation (Google BigQuery):** Clean transformation logic utilizing modular SQL queries, CTEs, window functions, and advanced filtering to generate Silver data models.
5. **Automated Silver Layer Export (BigQuery to Azure Storage):** Pipeline automatically executes SQL scripts and exports cleaned, structured CSV datasets directly into the `silver` Azure Blob Storage container for downstream consumption.
6. **Executive Visualization (Power BI):** Dynamic dashboard tracking revenue efficiency, dead mileage, and optimal shift patterns.

---

### 🛠️ Tech Stack & Architecture

- **Extraction & Ingestion:** Python (`requests`, `pandas`, `azure-storage-blob`, `python-dotenv`)
- **CI/CD & Orchestration:** GitHub Actions (Automated weekly Cron trigger & manual workflow dispatch)
- **Data Lake (Bronze Layer):** Azure Blob Storage (Container: `bronze` - raw data)
- **Data Warehousing & Transformation:** SQL / Google BigQuery (`CTE`, `WINDOW functions`, `SAFE_CAST`, modular `.sql` scripts)
- **Cleaned Data Storage (Silver Layer):** Azure Blob Storage (Container: `silver` - automated export of transformed datasets)
- **Business Intelligence & Visualization:** Power BI (DAX, Interactive Reporting)

---

### 🎯 Business Objectives

Main Objective: Identify operational and financial patterns to maximize actual net profit per driving hour, while minimizing vehicle wear and unproductive time.

An applied Data Analytics project based on my real-world activity as a licensed independent professional (PFA) within the Bolt platform, starting 25 February 2026.

1. **Financial Target:** Maintain a consistent gross revenue between **2,000 - 2,500 LEI / week**.
2. **Time Efficiency:** Compress working hours **under 40 online hours / week** by targeting high-yield time slots.
3. **Resource Sustainability:** Minimize vehicle wear (VW Touran 1.6 TDI DSG) by reducing dead mileage ("dead kilometers") and avoiding heavy stop-and-go traffic.

---

### 📈 Key Data Insights & Findings analyzing operational records from `25.02.2026 to 06.06.2026`:

#### 1. Speed Profile & Traffic Bottlenecks (Q1, Q2, Q3)

- **Overall Average Speed:** A standard completed ride averages **6.1 km** and takes **15.7 minutes**, at an average speed of **23.5 km/h**.
- **Daytime Operational Block:** Between **07:00 - 17:00**, traffic collapses speeds to an absolute low of **14.4 km/h** (at 07:00). Ride volume remains low (4 - 50 cumulative rides historically), turning this window into a waste of time and fuel.
- **The Golden Window:** Between **18:00 - 23:00**, speed increases steadily (**20.6 - 28.6 km/h**), overlapping with the highest order volume (peaks of **147 - 189 rides** at 20:00 - 21:00).
- **Optimal Days:** Sunday (**26.4 km/h**) and Saturday (**25.6 km/h**) offer the best traffic fluidity. Thursday is the slowest day (**20.2 km/h**).

#### 2. Financial Efficiency & Hotspots (Q4, Q5, Q6, Q7)

- **Earnings per Minute:** Afternoons (10:00 - 15:00) deliver a critical minimum of **0.8 - 1.0 LEI / minute**. Conversely, night shifts (23:00 - 03:00) skyrocket to **1.5 - 2.3 LEI / minute**.
- **Top Weekly Intervals (Elite):** Sunday morning at 02:00 holds the absolute historical record of **112.6 LEI / hour**, followed closely by 03:00 at **100.4 LEI / hour**, and Saturday midnight at **87.9 LEI / hour**.
- **Cash vs. Card Correlation (Q12):** Both payment methods deliver identical financial performance (**1.4 LEI / minute** and **3.6 - 3.7 LEI / km**), proving both flows must be treated with equal operational priority.

#### 3. Distance Optimization & Dead Mileage (Q8, Q9, Q10)

- **Ride Segmentation:** Short rides (0-3 km) are the most profitable per unit of time, generating **1.7 LEI / minute** and **5.4 LEI / km**, with minimal pickup distances (**1.0 km**). Long rides (>8 km) drop to **2.8 LEI / km**.
- **Unproductive Rushing:** The **05:00** hour mark is the most inefficient, generating **44.5% dead mileage**. The **21:00** slot represents the historical low for dead mileage (**17.6%**).
- **Utilization Rate:** Maintaining an average app utilization rate of **84.7%** scales the overall hourly net profit to **60.74 LEI / hour**. On peak days with **95.1%** utilization, net earnings reach **92.6 LEI / hour**.

#### 4. Long-Term Strategy Validation (Q11)

- **Operational Evolution:** Macro analysis highlights the transition from the debut phase (week of Mar-02), where I worked an inefficient maximum of **48.0 hours** to generate **2,286.9 LEI** (**47.6 LEI / hour**), to the maturity phase (week of May-25), yielding a record **2,460.6 LEI** in just **30.7 online hours** (**80.2 LEI / hour**).

---

### ⚡ Synthesized Operational Strategy (Act)

| What I Do (Maximize Efficiency)                                                                             | What I AVOID (Eliminate Waste Time)                                                                             |
| :---------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| Focus driving hours strictly inside a **Compressed Work Week** (30-35 online hours) using the Top 20 slots. | **Avoid the 07:00 - 16:00 weekday window** to prevent getting stuck in heavy traffic below 17 km/h.             |
| Secure maximum presence during **nighttime weekends** (Saturday & Sunday, 22:00 - 04:00).                   | **Do not cancel rides prematurely** as a driver; always wait the full 5-minute timer to secure the no-show fee. |
| Prioritize **short rides (0-3 km)** in high-density sectors for a fast pace of 1.7 LEI / minute.            | **Do not accept long rides during heavy traffic** or pickup dispatches that exceed 1.5 dead km.                 |

---

### 📂 Repository Structure

- `/.github/workflows/` - GitHub Actions CI/CD pipeline (`weekly_extraction.yml`).
- `/python/` - Production extraction script (`bolt_fleet_extractor.py`).
- `/data/` - Local ingestion root (Contains `data_bronze/` local folder, ignored in Git for privacy).
- `/sql/` - BigQuery SQL transformation scripts and analytical query exports.
- `/docs/` - Full detailed analysis reports for each query.
- `/powerbi/` - Power BI template and dashboard files.
- `/images/` - Visual assets and dashboard presentation GIFs.

---

### 🎛️ Project Dashboard

- **Download the local report file from the repository: [📊 Download Power BI File](./powerbi/Bolt_Analysis_Silviu.pbix)**

---

## 🇷🇴 Versiunea in Romana

### 📌 Prezentare Generală a Proiectului

Un **pipeline complet de Data Engineering și Business Intelligence** care analizează performanța operațională și financiară a platformei de ride-sharing Bolt în București.

Acest proiect acoperă întregul ciclu de viață al datelor:

1. **Extragere Automatizată Enterprise (Python + REST API):** Ingestionare incrementală săptămânală și completare retroactivă (backfill) a datelor operaționale brute (`orders`, `state_logs`, `drivers`, `vehicles`).
2. **Orchestrare Automatizată CI/CD (GitHub Actions):** Joburi programate săptămânal în cloud pentru rularea întregului flux (extragere Python, execuție scripturi SQL în BigQuery și export automat de date).
3. **Stocare Securizată în Cloud (Azure Blob Storage - Stratul Bronze):** Stocare sigură pentru fișiere brute JSON/CSV, izolată de depozitele publice pentru confidențialitate și securitate.
4. **Data Warehousing & Transformare SQL (Google BigQuery):** Logică de transformare curată folosind interogări SQL modulare, structuri CTE, funcții analitice de tip window și filtrare avansată pentru generarea modelelor de date Silver.
5. **Export Automatizat în Stratul Silver (BigQuery la Azure Storage):** Pipeline-ul execută automat scripturile SQL și exportă seturile de date curățate și structurate (în format CSV) direct în containerul `silver` din Azure Blob Storage pentru analiză ulterioară.
6. **Vizualizare Executivă (Power BI):** Dashboard dinamic care urmărește eficiența veniturilor, kilometrajul parcurs fără client (dead mileage) și tiparele optime de lucru pe ture.

---

### 🛠️ Tehnologii Utilizate și Arhitectură

- **Extragere și Ingestionare:** Python (`requests`, `pandas`, `azure-storage-blob`, `python-dotenv`)
- **CI/CD și Orchestrare:** GitHub Actions (Declanșator automatizat Cron săptămânal și lansare manuală)
- **Data Lake (Stratul Bronze):** Azure Blob Storage (Container: `bronze` - date brute)
- **Data Warehousing și Transformare:** SQL / Google BigQuery (`CTE`, `WINDOW functions`, `SAFE_CAST`, interogări modulare `.sql`)
- **Stocare Date Curățate (Stratul Silver):** Azure Blob Storage (Container: `silver` - export automatizat de date transformate)
- **Business Intelligence și Vizualizare:** Power BI (DAX, Raportare Interactivă)

---

### 🎯 Obiectivele Proiectului de Business

Obiectivul principal: Identificarea tiparelor operationale si financiare pentru a maximiza profitul net real pe ora de condus, minimizand in acelasi timp uzura vehiculului si timpii neproductivi.

Este un proiect de Data Analytics aplicat, bazat pe activitatea mea reala ca sofer autorizat (PFA) in cadrul platformei Bolt, incepand cu 25 februarie 2026.

1. **Target Financiar:** Mentinerea unui venit brut intre **2000 - 2500 LEI / saptamana**.
2. **Eficienta Timpului:** Comprimarea timpului de lucru **sub 40 de ore online / saptamana**.
3. **Sustenabilitatea Resurselor:** Minimizarea uzurii tehnice a vehiculului (VW Touran 1.6 TDI DSG) prin reducerea kilometrilor parcursi in gol ("kilometri morti") si evitarea traficului greu (regim stop-and-go).

---

### 📈 Rezultate si Insights Cheie Analizand datele operationale din perioada `25.02.2026 - 06.06.2026`:

#### 1. Profilul Vitezei si Blocajele din Trafic (Q1, Q2, Q3)

- **Viteza medie generala:** O cursa standard are in medie **6.1 km** si dureaza **15.7 minute**, la o viteza medie de **23.5 km/h**.
- **Blocajul operational de zi:** Intre orele **07:00 - 17:00**, traficul prabuseste viteza la un minim de **14.4 km/h** (ora 07:00). Volumul de curse ramane scazut (4 - 50 curse in istoric), transformand intervalul intr-o risipa de timp si combustibil.
- **Fereastra de aur:** Intre orele **18:00 - 23:00**, viteza creste constant (**20.6 - 28.6 km/h**), suprapunandu-se pe cel mai mare volum de comenzi (varfuri de **147 - 189 de curse** la orele 20:00 - 21:00).
- **Zile optime:** Duminica (**26.4 km/h**) si Sambata (**25.6 km/h**) ofera cea mai mare fluiditate. Joi este cea mai lenta zi (**20.2 km/h**).

#### 2. Eficienta Financiara si Hotspots (Q4, Q5, Q6, Q7)

- **Randamentul pe minut:** Amiezile (10:00 - 15:00) livreaza un minim critic de **0.8 - 1.0 LEI / minut**. In schimb, noptile (23:00 - 03:00) urca la **1.5 - 2.3 LEI / minut**.
- **Top intervale saptamanale (Elite):** Duminica dimineata la ora 02:00 inregistreaza recordul absolut de **112.6 LEI / ora**, urmata de ora 03:00 cu **100.4 LEI / ora** si Sambata la miezul noptii cu **87.9 LEI / ora**.
- **Corelatia Cash vs Card (Q12):** Ambele metode de plata au performante financiare identice (**1.4 LEI / minut** si **3.6 - 3.7 LEI / km**), demonstrand ca ambele fluxuri trebuie tratate cu egala prioritate.

#### 3. Optimizarea Distantelor si Kilometrii Morti (Q8, Q9, Q10)

- **Segmentarea curselor:** Cursele scurte (0-3 km) sunt cele mai rentabile pe timp, generand **1.7 LEI / minut** si **5.4 LEI / km**, avand preluari minime (**1.0 km**). Cursele lungi (>8 km) scad la **2.8 LEI / km**.
- **Rularea in gol:** Ora **05:00** este cea mai ineficienta, generand **44.5% kilometri morti**. Ora **21:00** reprezinta minimul istoric de rulare in gol (**17.6%**).
- **Rata de utilizare:** Mentinerea unei rate medii de utilizare a aplicatiei de **84.7%** scaleaza castigul mediu general la **60.74 LEI / ora**. In zilele de varf, cand utilizarea atinge **95.1%**, castigul net urca la **92.6 LEI / ora**.

#### 4. Validarea Strategiei pe Termen Lung (Q11)

- **Evolutia operationala:** Analiza macro arata tranzitia de la faza de debut (saptamana 02-Mar), unde am lucrat un maxim ineficient de **48.0 ore** pentru **2,286.9 LEI** (**47.6 LEI / ora**), la faza de maturitate (saptamana 25-May), unde am realizat un record de **2,460.6 LEI** in doar **30.7 ore online**, ridicand randamentul la **80.2 LEI / ora**.

---

### ⚡ Strategia Operationala Sintetizata (Act)

| Ce Fac (Maximizare Eficienta)                                                                        | Ce NU Fac (Evitare Timp Mort)                                                                                             |
| :--------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------ |
| Conduc concentrat in **Saptamana Comprimata** (30-35 ore online) folosind exclusiv Top 20 intervale. | **Evit intervalul 07:00 - 16:00** in timpul saptamanii pentru a nu ramane blocat in trafic la viteze sub 17 km/h.         |
| Sunt prezent pe traseu in **weekend-ul nocturn** (Sambata si Duminica, orele 22:00 - 04:00).         | **Nu anulez prematur cursele** din pozitia de sofer inainte de cele 5 minute regulamentare pentru a asigura taxa no-show. |
| Prioritizez **cursele scurte (0-3 km)** in zone dense pentru un randament rapid de 1.7 LEI / minut.  | **Nu accept curse lungi in trafic intens** sau preluari in gol ce depasesc 1.5 km.                                        |

---

### 📂 Structura Repository-ului

### 📂 Structura Repository-ului

- `/.github/workflows/` - Pipeline CI/CD GitHub Actions (`weekly_extraction.yml`).
- `/python/` - Scriptul Python de extragere si incarcare Azure (`bolt_fleet_extractor.py`).
- `/data/` - Folder radacina pentru date locale (`data_bronze/` este ignorat in Git pentru confidentialitate).
- `/sql/` - Interogari SQL BigQuery si exporturile rezultatelor analitice.
- `/docs/` - Analize detaliate pentru fiecare interogare SQL.
- `/powerbi/` - Fisierul de raportare Power BI.
- `/images/` - Resurse vizuale si GIF-uri de prezentare.

---

### 🎛️ Dashboard Proiect

- **Poti descarca fisierul local direct din repository: [📊 Descarca fisierul Power BI](./powerbi/Bolt_Analysis_Silviu.pbix)**
