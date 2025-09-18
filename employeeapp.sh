#!/bin/bash
# Employee Management App Installer - PHP + MySQL + Apache

set -e

echo "🚀 Updating system & installing dependencies..."
if [ -f /etc/debian_version ]; then
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install apache2 mysql-server php libapache2-mod-php php-mysql unzip wget -y
    sudo systemctl enable apache2
    sudo systemctl start apache2
    WEBROOT="/var/www/html"
elif [ -f /etc/redhat-release ]; then
    sudo yum update -y
    sudo yum install httpd mysql-server php php-mysqlnd unzip wget -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    WEBROOT="/var/www/html"
else
    echo "Unsupported OS. Use Ubuntu/Debian or RHEL/CentOS."
    exit 1
fi

sudo systemctl enable mysql
sudo systemctl start mysql
echo "✅ LAMP stack installed."

# Database setup
DB_NAME="employeedb"
DB_USER="empuser"
DB_PASS="7muf8BwD6@2q7"

echo "🚀 Setting up MySQL database and user..."
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;

USE $DB_NAME;
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id VARCHAR(50) UNIQUE,
    name VARCHAR(100),
    department VARCHAR(100),
    salary DECIMAL(10,2),
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255)
);

INSERT IGNORE INTO admin (username, password) VALUES ('admin', MD5('admin123'));
EOF
echo "✅ Database ready."

# Deploy application
APP_DIR="$WEBROOT"
sudo rm -rf $APP_DIR
sudo mkdir -p $APP_DIR

echo "🚀 Deploying Employee App..."

# db.php
cat << 'PHP' | sudo tee $APP_DIR/db.php > /dev/null
<?php
$host = "localhost";
$user = "empuser";
$pass = "7muf8BwD6@2q7";
$dbname = "employeedb";

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
PHP

# index.php (Login)
cat << 'PHP' | sudo tee $APP_DIR/index.php > /dev/null
<?php
session_start();
include 'db.php';

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $sql = "SELECT * FROM employees WHERE username=? AND password=?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, md5($password));
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows == 1) {
        $_SESSION['user'] = $username;
        header("Location: dashboard.php");
        exit;
    }

    $sql = "SELECT * FROM admin WHERE username=? AND password=?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $username, md5($password));
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows == 1) {
        $_SESSION['admin'] = $username;
        header("Location: admin.php");
        exit;
    }

    $error = "Invalid credentials!";
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
  <div class="card shadow p-4">
    <h2 class="mb-3 text-center">Login</h2>
    <?php if (!empty($error)) echo "<div class='alert alert-danger'>$error</div>"; ?>
    <form method="post">
      <div class="mb-3">
        <label class="form-label">Username</label>
        <input type="text" name="username" class="form-control" required>
      </div>
      <div class="mb-3">
        <label class="form-label">Password</label>
        <input type="password" name="password" class="form-control" required>
      </div>
      <button type="submit" class="btn btn-primary w-100">Login</button>
    </form>
    <div class="mt-3 text-center">
      <a href="register.php" class="btn btn-link">Register as Employee</a>
    </div>
  </div>
</div>
</body>
</html>
PHP

# register.php
cat << 'PHP' | sudo tee $APP_DIR/register.php > /dev/null
<?php
include 'db.php';

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $name = $_POST['name'];
    $emp_id = $_POST['emp_id'];
    $dept = $_POST['department'];
    $salary = $_POST['salary'];
    $username = $_POST['username'];
    $password = md5($_POST['password']);

    $sql = "INSERT INTO employees (emp_id, name, department, salary, username, password)
            VALUES (?,?,?,?,?,?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssssss", $emp_id, $name, $dept, $salary, $username, $password);
    
    if ($stmt->execute()) {
        echo "<div class='alert alert-success'>Registration successful! <a href='index.php'>Login</a></div>";
    } else {
        echo "<div class='alert alert-danger'>Error: " . $conn->error . "</div>";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
  <title>Employee Registration</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4">
    <h2 class="mb-3">Employee Registration</h2>
    <form method="post">
      <div class="mb-3"><label class="form-label">Employee ID</label><input type="text" name="emp_id" class="form-control" required></div>
      <div class="mb-3"><label class="form-label">Name</label><input type="text" name="name" class="form-control" required></div>
      <div class="mb-3"><label class="form-label">Department</label><input type="text" name="department" class="form-control" required></div>
      <div class="mb-3"><label class="form-label">Salary</label><input type="number" step="0.01" name="salary" class="form-control" required></div>
      <div class="mb-3"><label class="form-label">Username</label><input type="text" name="username" class="form-control" required></div>
      <div class="mb-3"><label class="form-label">Password</label><input type="password" name="password" class="form-control" required></div>
      <button type="submit" class="btn btn-success w-100">Register</button>
    </form>
  </div>
</div>
</body>
</html>
PHP

# dashboard.php
cat << 'PHP' | sudo tee $APP_DIR/dashboard.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['user'])) {
    header("Location: index.php");
    exit;
}

$username = $_SESSION['user'];
$sql = "SELECT * FROM employees WHERE username=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();
$emp = $result->fetch_assoc();
?>
<!DOCTYPE html>
<html>
<head>
  <title>Employee Dashboard</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4">
    <h2 class="mb-3 text-center">Welcome, <?php echo $emp['name']; ?></h2>
    <h5>Your Details</h5>
    <table class="table table-bordered">
      <tr><th>Employee ID</th><td><?php echo $emp['emp_id']; ?></td></tr>
      <tr><th>Name</th><td><?php echo $emp['name']; ?></td></tr>
      <tr><th>Department</th><td><?php echo $emp['department']; ?></td></tr>
      <tr><th>Salary</th><td><?php echo $emp['salary']; ?></td></tr>
      <tr><th>Username</th><td><?php echo $emp['username']; ?></td></tr>
    </table>
    <div class="mt-3 text-center">
      <a href="details.php" class="btn btn-info">Update Details</a>
      <a href="logout.php" class="btn btn-danger">Logout</a>
    </div>
  </div>
</div>
</body>
</html>
PHP

# details.php
cat << 'PHP' | sudo tee $APP_DIR/details.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['user'])) {
    header("Location: index.php");
    exit;
}

$username = $_SESSION['user'];
$sql = "SELECT * FROM employees WHERE username=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();
$emp = $result->fetch_assoc();

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $dept = $_POST['department'];
    $salary = $_POST['salary'];

    $update = "UPDATE employees SET department=?, salary=? WHERE username=?";
    $stmt = $conn->prepare($update);
    $stmt->bind_param("sss", $dept, $salary, $username);
    $stmt->execute();
    $success = "Details updated successfully!";
}
?>
<!DOCTYPE html>
<html>
<head>
  <title>Update Details</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4">
    <h2 class="mb-3">Update Your Details</h2>
    <?php if (!empty($success)) echo "<div class='alert alert-success'>$success</div>"; ?>
    <form method="post">
      <div class="mb-3"><label class="form-label">Name</label><input type="text" value="<?php echo $emp['name']; ?>" class="form-control" disabled></div>
      <div class="mb-3"><label class="form-label">Department</label><input type="text" name="department" value="<?php echo $emp['department']; ?>" class="form-control"></div>
      <div class="mb-3"><label class="form-label">Salary</label><input type="number" step="0.01" name="salary" value="<?php echo $emp['salary']; ?>" class="form-control"></div>
      <button type="submit" class="btn btn-primary w-100">Update</button>
    </form>
    <div class="mt-3 text-center">
      <a href="dashboard.php" class="btn btn-secondary">⬅ Go Back</a>
    </div>
  </div>
</div>
</body>
</html>
PHP

# admin.php
cat << 'PHP' | sudo tee $APP_DIR/admin.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['admin'])) {
    header("Location: index.php");
    exit;
}
$result = $conn->query("SELECT * FROM employees");
?>
<!DOCTYPE html>
<html>
<head>
  <title>Admin Dashboard</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4">
    <h2 class="mb-3">Admin Dashboard</h2>
    <table class="table table-striped table-bordered">
      <thead class="table-dark">
        <tr><th>ID</th><th>Name</th><th>Department</th><th>Salary</th><th>Username</th><th>Actions</th></tr>
      </thead>
      <tbody>
      <?php while ($row = $result->fetch_assoc()) { ?>
        <tr>
          <td><?php echo $row['emp_id']; ?></td>
          <td><?php echo $row['name']; ?></td>
          <td><?php echo $row['department']; ?></td>
          <td><?php echo $row['salary']; ?></td>
          <td><?php echo $row['username']; ?></td>
          <td>
            <a href="edit_employee.php?id=<?php echo $row['id']; ?>" class="btn btn-warning btn-sm">Edit</a>
            <a href="delete_employee.php?id=<?php echo $row['id']; ?>" class="btn btn-danger btn-sm" onclick="return confirm('Are you sure?');">Delete</a>
          </td>
        </tr>
      <?php } ?>
      </tbody>
    </table>
    <div class="mt-3 text-center">
      <a href="logout.php" class="btn btn-secondary">Logout</a>
    </div>
  </div>
</div>
</body>
</html>
PHP

# edit_employee.php
cat << 'PHP' | sudo tee $APP_DIR/edit_employee.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['admin'])) {
    header("Location: index.php");
    exit;
}
$id = $_GET['id'];
$sql = "SELECT * FROM employees WHERE id=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();
$emp = $result->fetch_assoc();
if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $name = $_POST['name'];
    $dept = $_POST['department'];
    $salary = $_POST['salary'];
    $update = "UPDATE employees SET name=?, department=?, salary=? WHERE id=?";
    $stmt = $conn->prepare($update);
    $stmt->bind_param("sssi", $name, $dept, $salary, $id);
    $stmt->execute();
    header("Location: admin.php");
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
  <title>Edit Employee</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
  <div class="card shadow p-4">
    <h2 class="mb-3">Edit Employee</h2>
    <form method="post">
      <div class="mb-3"><label class="form-label">Name</label><input type="text" name="name" value="<?php echo $emp['name']; ?>" class="form-control"></div>
      <div class="mb-3"><label class="form-label">Department</label><input type="text" name="department" value="<?php echo $emp['department']; ?>" class="form-control"></div>
      <div class="mb-3"><label class="form-label">Salary</label><input type="number" step="0.01" name="salary" value="<?php echo $emp['salary']; ?>" class="form-control"></div>
      <button type="submit" class="btn btn-primary w-100">Update</button>
    </form>
  </div>
</div>
</body>
</html>
PHP

# delete_employee.php
cat << 'PHP' | sudo tee $APP_DIR/delete_employee.php > /dev/null
<?php
session_start();
include 'db.php';
if (!isset($_SESSION['admin'])) {
    header("Location: index.php");
    exit;
}
if (isset($_GET['id'])) {
    $id = intval($_GET['id']);
    $sql = "DELETE FROM employees WHERE id=?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);
    $stmt->execute();
}
header("Location: admin.php");
exit;
?>
PHP

# logout.php
cat << 'PHP' | sudo tee $APP_DIR/logout.php > /dev/null
<?php
session_start();
session_destroy();
header("Location: index.php");
exit;
?>
PHP

sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR

echo "✅ Employee App deployed at: http://YOUR_SERVER_IP/employee_app"
echo "🔑 Admin Login: username=admin, password=admin123"
