# LMNH Customer Review Pipeline

Real-time ETL pipeline for processing visitor interactions (reviews and incidents) from the Liverpool Natural History Museum.

## LMNH Presentation Drive Link
[LMNH Presentation](https://drive.google.com/drive/folders/1_K_yYGl9TYV92TLCzJ0R-a25mfN5xwhf?usp=sharing)

## Architecture

**Single-stage pipeline system:**
- **Kafka Consumer**: Continuously reads messages from `"lmnh"` topic → validates and transforms → loads to PostgreSQL (local or AWS RDS) → visualized on Tableau Dashboard

## Quick Start

### Prerequisites
- Python 3.x
- Kafka cluster
- PostgreSQL database
- AWS configured

### 1. Clone and Setup

```bash
git clone https://github.com/KieranPhelan/LMNH-Customer-Review-Pipeline.git
cd LMNH-Customer-Review-Pipeline
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Configure Environment

Create a `.env` file in the project root:

```env
# Kafka
BOOTSTRAP_SERVERS=your-kafka-bootstrap-servers
SECURITY_PROTOCOL=SASL_SSL
SASL_MECHANISM=PLAIN
USERNAME=your-kafka-username
PASSWORD=your-kafka-password
GROUP_ID=your-consumer-group
AUTO_OFFSET=earliest

# Local Database
LOCAL_DATABASE_NAME=museum
LOCAL_DATABASE_USERNAME=postgres
LOCAL_DATABASE_PASSWORD=your-password
LOCAL_DATABASE_IP=localhost
LOCAL_DATABASE_PORT=5432

# AWS RDS
DATABASE_NAME=museum
DATABASE_USERNAME=your-rds-username
DATABASE_PASSWORD=your-rds-password
DATABASE_IP=your-rds-endpoint.eu-west-2.rds.amazonaws.com
DATABASE_PORT=5432
```

### 3. Initialise Database Schema

```bash
cd schema
bash reset_interaction_data.sh
```

## Running the Pipeline

### Local Development (with local PostgreSQL)

```bash
cd pipeline
pip install -r requirements.txt
python3 consumer.py --local_db
```

### Production (AWS RDS)

```bash
cd pipeline
pip install -r requirements.txt
python3 consumer.py
```

### Command-Line Options

- `--load`: Enable/disable database writes (default: enabled)
- `--local_db`: Use local PostgreSQL instead of AWS RDS
- `-lr, --load_review`: Skip loading review data
- `-li, --load_incident`: Skip loading incident data

**Example**: `python consumer.py --local_db -lr` = Use local DB but skip reviews

## Infrastructure Deployment

Deploy AWS infrastructure using Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- RDS PostgreSQL database
- EC2 instance for running the consumer
- Security groups for database and EC2 access
- VPC and subnet configuration

## Project Structure

```
├── pipeline/
│   ├── consumer.py           # Main Kafka consumer & ETL logic
│   ├── requirements.txt      # Python dependencies
│   └── logs/                 # pipeline.log output
├── schema/
│   ├── schema.sql            # Table definitions
│   └── reset_interaction_data.sh  # Schema reset script
└── terraform/
    ├── main.tf              # AWS infrastructure
    ├── variables.tf         # Terraform variables
    └── terraform.tfvars     # Variable values
```

## Validation Rules

Messages are rejected if:
- Timestamp is not ISO format or > 0.9 seconds in future
- Recorded outside 8:45 AM–6:15 PM
- Site value outside 0–5 range
- Rating/value outside -1 to 4 range
- Incident type outside 0–1 (0=Assistance, 1=Emergency)
- Any field contains null values

Invalid messages are logged but never persisted to database.

## Key Features

- **Real-time ingestion**: Kafka consumer processes messages as they arrive
- **Strict validation**: Business rule enforcement at message level
- **Flexible deployment**: Local development or cloud-based (AWS RDS)
- **Safe SQL**: Parameterised queries prevent injection attacks
- **Comprehensive logging**: File-based logs for debugging message flow
- **Infrastructure as Code**: Fully reproducible AWS setup with Terraform

## Data Visualisation

The validated visitor interaction data is automatically visualised in a **Tableau Dashboard** that displays:
- Real-time review ratings and incident reports by exhibition
- Historical trends in visitor satisfaction
- Incident frequency and types

## Useful Commands

### Test Database Connection (Local)
```bash
psql -h localhost -U kieranphelan -d museum
```

### Check RDS Database Connection
```bash
psql -h your-rds-endpoint.eu-west-2.rds.amazonaws.com -U kieran_phelan -d museum
```

### View Pipeline Logs
```bash
tail -f pipeline/logs/pipeline.log
```

### Reset Schema
```bash
bash schema/reset_interaction_data.sh
```

### Deploy Infrastructure
```bash
cd terraform
terraform apply -var-file=terraform.tfvars
```
