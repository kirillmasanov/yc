CREATE TABLE IF NOT EXISTS load_balancer_requests (
    type            VARCHAR(24) NOT NULL,
    request_time    TIMESTAMP NOT NULL,
    http_status     VARCHAR(4) NOT NULL,
    backend_ip      VARCHAR(40) NULL,
    response_time   DECIMAL(10,2) NULL
);

CREATE TABLE IF NOT EXISTS my_app_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
