-- Petsupplies sync backend schema (MySQL 8, InnoDB, utf8mb4).
-- Mirrors the Flutter app's local tables (lib/data/local_database.dart, lib/models/app_models.dart).
-- IDs are UUID strings. Every syncable table carries updated_at / is_deleted / server_seq.
-- server_seq is issued from the one-row `server_sequence` counter (NOT AUTO_INCREMENT,
-- which does not advance on UPDATE); read-and-increment logic lives in the sync code.

CREATE TABLE IF NOT EXISTS server_sequence (
  seq BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO server_sequence (seq) SELECT 0 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM server_sequence);

CREATE TABLE IF NOT EXISTS categories (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  color_value INT NOT NULL,
  is_protected TINYINT(1) NOT NULL DEFAULT 0,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_categories_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS inventory_items (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  category VARCHAR(190) NOT NULL,
  stock INT NOT NULL,
  reorder_level INT NOT NULL,
  unit_cost DECIMAL(12,2) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  variant VARCHAR(190) NOT NULL DEFAULT '',
  variants LONGTEXT NULL,
  sku VARCHAR(190) NOT NULL DEFAULT '',
  representation VARCHAR(50) NOT NULL DEFAULT 'color_shape',
  display_color_value INT NOT NULL DEFAULT 0,
  display_shape VARCHAR(50) NOT NULL DEFAULT 'rounded_square',
  image_path VARCHAR(500) NOT NULL DEFAULT '',
  image_url VARCHAR(500) NOT NULL DEFAULT '',
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_inventory_items_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS discounts (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  type VARCHAR(50) NOT NULL,
  value DECIMAL(12,2) NOT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_discounts_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS receipts (
  id CHAR(36) NOT NULL PRIMARY KEY,
  number VARCHAR(100) NOT NULL,
  date VARCHAR(50) NOT NULL,
  time VARCHAR(50) NOT NULL,
  items INT NOT NULL,
  purchased_items LONGTEXT NULL,
  store_name VARCHAR(190) NOT NULL DEFAULT 'Meng''s Store',
  cashier VARCHAR(190) NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  is_highlighted TINYINT(1) NOT NULL DEFAULT 0,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_receipts_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS expense_types (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  UNIQUE KEY uniq_expense_types_name (name),
  KEY idx_expense_types_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS expenses (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  category VARCHAR(190) NOT NULL DEFAULT 'General',
  amount DECIMAL(12,2) NOT NULL,
  date VARCHAR(50) NOT NULL,
  note TEXT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_expenses_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_accounts (
  id CHAR(36) NOT NULL PRIMARY KEY,
  username VARCHAR(190) NOT NULL,
  password VARCHAR(255) NOT NULL,
  display_name VARCHAR(190) NOT NULL,
  role VARCHAR(30) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  UNIQUE KEY uniq_user_accounts_username (username),
  KEY idx_user_accounts_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS loans (
  id CHAR(36) NOT NULL PRIMARY KEY,
  borrower_name VARCHAR(190) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  date VARCHAR(50) NOT NULL,
  note TEXT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_loans_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS suppliers (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  contact_person VARCHAR(190) NOT NULL DEFAULT '',
  phone_number VARCHAR(50) NOT NULL DEFAULT '',
  address VARCHAR(500) NOT NULL DEFAULT '',
  note TEXT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_suppliers_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS purchase_orders (
  id CHAR(36) NOT NULL PRIMARY KEY,
  number VARCHAR(100) NOT NULL,
  supplier_name VARCHAR(190) NOT NULL,
  date VARCHAR(50) NOT NULL,
  time VARCHAR(50) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  note TEXT NULL,
  line_items LONGTEXT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_purchase_orders_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stock_adjustments (
  id CHAR(36) NOT NULL PRIMARY KEY,
  number VARCHAR(100) NOT NULL,
  inventory_item_id CHAR(36) NOT NULL,
  item_name VARCHAR(190) NOT NULL,
  category VARCHAR(190) NOT NULL,
  sku VARCHAR(190) NOT NULL DEFAULT '',
  date VARCHAR(50) NOT NULL,
  time VARCHAR(50) NOT NULL,
  adjustment_type VARCHAR(50) NOT NULL,
  reason VARCHAR(190) NOT NULL,
  quantity INT NOT NULL,
  previous_stock INT NOT NULL,
  resulting_stock INT NOT NULL,
  variant_name VARCHAR(190) NOT NULL DEFAULT '',
  note TEXT NULL,
  representation VARCHAR(50) NOT NULL DEFAULT 'color_shape',
  display_color_value INT NOT NULL DEFAULT 0,
  display_shape VARCHAR(50) NOT NULL DEFAULT 'rounded_square',
  image_path VARCHAR(500) NOT NULL DEFAULT '',
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_stock_adjustments_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stock_movements (
  id CHAR(36) NOT NULL PRIMARY KEY,
  inventory_item_id CHAR(36) NOT NULL,
  variant_name VARCHAR(190) NOT NULL DEFAULT '',
  delta INT NOT NULL,
  source_type VARCHAR(20) NOT NULL,
  source_id CHAR(36) NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  server_seq BIGINT NOT NULL,
  KEY idx_stock_movements_item (inventory_item_id),
  KEY idx_stock_movements_server_seq (server_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS auth_tokens (
  token CHAR(64) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  created_at BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
