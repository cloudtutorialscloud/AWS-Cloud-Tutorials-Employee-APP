#!/bin/bash
# Employee Management App Installer - EC2 + AWS RDS (MySQL)
# Author: Joseph
# Description: Installs Apache + PHP, connects to RDS, creates DB + tables, deploys app.

set -e

echo "🚀 Updating system & installing dependencies..."
if [ -f /etc/debian_version ]; then
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install apache2 php libapache2-mod-php php-mysql unzip wget -y
    sudo systemctl enable apache2
    sudo systemctl start apache2
    WEBROOT="/var/www/html"
elif [ -f /etc/redhat-release ]; then
    sudo yum update -y
    sudo yum install httpd php php-mysqlnd unzip wget -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    WEBROOT="/var/www/html"
else
    echo "❌ Unsupported OS. Use Ubuntu/Debian or RHEL/CentOS."
    exit 1
fi

echo "✅ Apache & PHP installed successfully."

# ------------------------------------------------------------------------------
# 1️⃣ RDS CONFIGURATION — replace with your real credentials
# ------------------------------------------------------------------------------
RDS_ENDPOINT="database-1.ckzlx11n8uhe.us-east-1.rds.amazonaws.com"
RDS_USER="admin"
RDS_PASS="networkB2#"
RDS_DBNAME="employeedb"

# ------------------------------------------------------------------------------
# 2️⃣ CREATE DATABASE AND TABLES ON RDS
# ------------------------------------------------------------------------------
echo "🧱 Setting up database on RDS..."

php <<PHP
<?php
\$host = "$RDS_ENDPOINT";
\$user = "$RDS_USER";
\$pass = "$RDS_PASS";
\$dbname = "$RDS_DBNAME";

\$conn = new mysqli(\$host, \$user, \$pass);
if (\$conn->connect_error) {
    die("❌ Connection failed: " . \$conn->connect_error . PHP_EOL);
}
echo "✅ Connected to RDS.\n";

// Create database if not exists
\$conn->query("CREATE DATABASE IF NOT EXISTS \$dbname");
echo "📦 Database ensured: \$dbname\n";

\$conn->select_db(\$dbname);

// Create employees table
\$createEmployees = "CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    username VARCHAR(50) UNIQUE,
    password VARCHAR(100)
)";
\$conn->query(\$createEmployees);
echo "🧩 Table ensured: employees\n";

// Create admin table
\$createAdmin = "CREATE TABLE IF NOT EXISTS admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(100)
)";
\$conn->query(\$createAdmin);
echo "🧩 Table ensured: admin\n";

// Insert default admin if not exists
\$adminCheck = \$conn->query("SELECT * FROM admin WHERE username='admin'");
if (\$adminCheck->num_rows == 0) {
    \$conn->query("INSERT INTO admin (username, password) VALUES ('admin', MD5('admin123'))");
    echo "🔑 Default admin created: username=admin | password=admin123\n";
} else {
    echo "ℹ️ Admin user already exists.\n";
}

\$conn->close();
?>
PHP

# ------------------------------------------------------------------------------
# 3️⃣ DEPLOY PHP APPLICATION FILES
# ------------------------------------------------------------------------------
APP_DIR="$WEBROOT"
sudo rm -rf $APP_DIR
sudo mkdir -p $APP_DIR

echo "🚀 Deploying Employee Management Web App..."

# -------------------- db.php --------------------
cat <<PHP | sudo tee $APP_DIR/db.php > /dev/null
<?php
\$host = "$RDS_ENDPOINT";
\$user = "$RDS_USER";
\$pass = "$RDS_PASS";
\$dbname = "$RDS_DBNAME";

\$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
if (\$conn->connect_error) {
    die("Database connection failed: " . \$conn->connect_error);
}
?>
PHP

# -------------------- index.php (login) --------------------
cat <<'PHP' | sudo tee $APP_DIR/index.php > /dev/null
<?php
session_start();
include 'db.php';

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $sql = "SELECT * FROM employees WHERE username=? AND password=MD5(?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($res->num_rows == 1) {
        $_SESSION['user'] = $username;
        header("Location: dashboard.php");
        exit;
    }

    $sql = "SELECT * FROM admin WHERE username=? AND password=MD5(?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($res->num_rows == 1) {
        $_SESSION['admin'] = $username;
        header("Location: admin.php");
        exit;
    }

    $error = "Invalid username or password!";
}
?>
<!DOCTYPE html>
<html>
<head>
<title>Login</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4 col-md-5 mx-auto">
    <h3 class="text-center mb-3">Employee Login</h3>
    <?php if (!empty($error)) echo "<div class='alert alert-danger'>$error</div>"; ?>
    <form method="post">
      <div class="mb-3"><input type="text" name="username" class="form-control" placeholder="Username" required></div>
      <div class="mb-3"><input type="password" name="password" class="form-control" placeholder="Password" required></div>
      <button class="btn btn-primary w-100">Login</button>
    </form>
    <div class="mt-3 text-center">
      <a href="register.php">Register as Employee</a>
    </div>
  </div>
</div>
</body>
</html>
PHP

# -------------------- register.php --------------------
cat <<'PHP' | sudo tee $APP_DIR/register.php > /dev/null
<?php
include 'db.php';
if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $emp_id = $_POST['emp_id'];
    $name = $_POST['name'];
    $department = $_POST['department'];
    $salary = $_POST['salary'];
    $username = $_POST['username'];
    $password = md5($_POST['password']);

    $sql = "INSERT INTO employees (emp_id, name, department, salary, username, password) VALUES (?,?,?,?,?,?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssssss", $emp_id, $name, $department, $salary, $username, $password);
    if ($stmt->execute()) {
        echo "<div class='alert alert-success'>Registered successfully! <a href='index.php'>Login here</a></div>";
    } else {
        echo "<div class='alert alert-danger'>Error: ".$conn->error."</div>";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<title>Register</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4 col-md-6 mx-auto">
    <h3 class="text-center mb-3">Employee Registration</h3>
    <form method="post">
      <input type="text" name="emp_id" class="form-control mb-2" placeholder="Employee ID" required>
      <input type="text" name="name" class="form-control mb-2" placeholder="Full Name" required>
      <input type="text" name="department" class="form-control mb-2" placeholder="Department" required>
      <input type="number" name="salary" class="form-control mb-2" placeholder="Salary" required>
      <input type="text" name="username" class="form-control mb-2" placeholder="Username" required>
      <input type="password" name="password" class="form-control mb-2" placeholder="Password" required>
      <button class="btn btn-success w-100">Register</button>
    </form>
  </div>
</div>
</body>
</html>
PHP

# -------------------- dashboard.php --------------------
cat <<'PHP' | sudo tee $APP_DIR/dashboard.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['user'])) { header("Location: index.php"); exit; }
$username = $_SESSION['user'];
$res = $conn->query("SELECT * FROM employees WHERE username='$username'");
$data = $res->fetch_assoc();
?>
<!DOCTYPE html>
<html>
<head>
<title>Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="card shadow p-4">
    <h3>Welcome, <?php echo $data['name']; ?></h3>
    <table class="table table-bordered mt-3">
      <tr><th>Employee ID</th><td><?php echo $data['emp_id']; ?></td></tr>
      <tr><th>Department</th><td><?php echo $data['department']; ?></td></tr>
      <tr><th>Salary</th><td><?php echo $data['salary']; ?></td></tr>
    </table>
    <a href="logout.php" class="btn btn-danger">Logout</a>
  </div>
</div>
</body>
</html>
PHP

# -------------------- admin.php --------------------
cat <<'PHP' | sudo tee $APP_DIR/admin.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['admin'])) { header("Location: index.php"); exit; }
$res = $conn->query("SELECT * FROM employees");
?>
<!DOCTYPE html>
<html>
<head>
<title>Admin Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="card shadow p-4">
    <h3>Admin Dashboard</h3>
    <table class="table table-bordered mt-3">
      <tr><th>ID</th><th>Name</th><th>Department</th><th>Salary</th><th>Username</th></tr>
      <?php while($r=$res->fetch_assoc()){ ?>
        <tr><td><?php echo $r['emp_id']; ?></td><td><?php echo $r['name']; ?></td><td><?php echo $r['department']; ?></td><td><?php echo $r['salary']; ?></td><td><?php echo $r['username']; ?></td></tr>
      <?php } ?>
    </table>
    <a href="logout.php" class="btn btn-secondary">Logout</a>
  </div>
</div>
</body>
</html>
PHP

# -------------------- logout.php --------------------
cat <<'PHP' | sudo tee $APP_DIR/logout.php > /dev/null
<?php
session_start();
session_destroy();
header("Location: index.php");
exit;
?>
PHP
# S3 image configuration
S3_IMAGE_URL="https://12345lulu789.s3.us-east-1.amazonaws.com/images.jpg"
for file in index.php register.php dashboard.php details.php admin.php edit_employee.php; do
  sudo sed -i "/<head>/a <style>body { background: url('$S3_IMAGE_URL') no-repeat center center fixed; background-size: cover; }</style>" $APP_DIR/$file
done
# ------------------------------------------------------------------------------
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR

# ------------------------------------------------------------------------------
echo "✅ App files deployed!"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "🌐 Access your app at: http://$PUBLIC_IP/"
echo "🔑 Default admin login: admin / admin123"
echo "🗄️ Database: $RDS_DBNAME on $RDS_ENDPOINT"
