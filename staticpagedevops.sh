#!/bin/bash

# Create project directory
mkdir -p website/pages

# Create CSS file
cat <<EOF > website/style.css
body {
    font-family: Arial, sans-serif;
    margin: 0;
    background-color: #f4f4f4;
}

header {
    background: #333;
    color: white;
    padding: 15px;
    text-align: center;
}

nav a {
    color: white;
    margin: 0 10px;
    text-decoration: none;
}

nav a:hover {
    text-decoration: underline;
}

section {
    padding: 20px;
}

footer {
    background: #333;
    color: white;
    text-align: center;
    padding: 10px;
    position: fixed;
    bottom: 0;
    width: 100%;
}
EOF

# Create index.html
cat <<EOF > website/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Home</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<header>
    <h1>My Website</h1>
    <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
        <a href="pages/services.html">Services</a>
        <a href="pages/contact.html">Contact</a>
    </nav>
</header>

<section>
    <h2>Welcome</h2>
    <p>This is the home page.</p>
</section>

<footer>
    <p>© 2026 My Website</p>
</footer>

</body>
</html>
EOF

# Create about.html
cat <<EOF > website/about.html
<!DOCTYPE html>
<html>
<head>
    <title>About</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<header>
    <h1>About Us</h1>
    <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
        <a href="pages/services.html">Services</a>
        <a href="pages/contact.html">Contact</a>
    </nav>
</header>

<section>
    <h2>About Page</h2>
    <p>This is the about page.</p>
</section>

<footer>
    <p>© 2026 My Website</p>
</footer>

</body>
</html>
EOF

# Create contact.html
cat <<EOF > website/pages/contact.html
<!DOCTYPE html>
<html>
<head>
    <title>Contact</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>

<header>
    <h1>Contact</h1>
    <nav>
        <a href="../index.html">Home</a>
        <a href="../about.html">About</a>
        <a href="services.html">Services</a>
        <a href="contact.html">Contact</a>
    </nav>
</header>

<section>
    <h2>Contact Us</h2>
    <p>Email: test@example.com</p>
</section>

<footer>
    <p>© 2026 My Website</p>
</footer>

</body>
</html>
EOF

# Create services.html
cat <<EOF > website/pages/services.html
<!DOCTYPE html>
<html>
<head>
    <title>Services</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>

<header>
    <h1>Services</h1>
    <nav>
        <a href="../index.html">Home</a>
        <a href="../about.html">About</a>
        <a href="services.html">Services</a>
        <a href="contact.html">Contact</a>
    </nav>
</header>

<section>
    <h2>Our Services</h2>
    <ul>
        <li>Web Development</li>
        <li>Cloud Deployment</li>
        <li>DevOps</li>
    </ul>
</section>

<footer>
    <p>© 2026 My Website</p>
</footer>

</body>
</html>
EOF

echo "Website files created successfully!"

# Optional: Deploy to Apache
read -p "Do you want to deploy to Apache web root? (y/n): " choice

if [ "$choice" == "y" ]; then
    sudo rm -rf /var/www/html/*
    sudo cp -r website/* /var/www/html/
    sudo systemctl restart apache2
    echo "Website deployed to Apache!"
else
    echo "Deployment skipped."
fi
