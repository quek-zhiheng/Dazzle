CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    address TEXT,
    name TEXT,
    account_closed BOOLEAN
);

CREATE TABLE shop (
    id SERIAL PRIMARY KEY,
    name TEXT
);

-- Combines Category, Has
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name TEXT,
    parent INTEGER REFERENCES category(id)
);

CREATE TABLE manufacturer (
    id SERIAL PRIMARY KEY,
    name TEXT,
    country TEXT
);

-- Combines Product, Belongs to, Manufactured by
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name TEXT,
    description TEXT,
    -- Enforce Key+TP constraint
    category INTEGER NOT NULL REFERENCES category(id),
    -- Enforce Key+TP constraint
    manufacturer INTEGER NOT NULL REFERENCES manufacturer(id)
);

CREATE TABLE sells (
    shop_id INTEGER REFERENCES shop(id),
    product_id INTEGER REFERENCES product(id),
    sell_timestamp TIMESTAMP,
    price NUMERIC,
    quantity INTEGER,
    PRIMARY KEY (shop_id, product_id, sell_timestamp)
);

CREATE TABLE coupon_batch (
    id SERIAL PRIMARY KEY,
    valid_period_start DATE,
    valid_period_end DATE,
    reward_amount NUMERIC,
    min_order_amount NUMERIC,
    -- Enforce constraint that reward amount is lower than minimum order_amount
    CHECK (reward_amount <= min_order_amount),
    -- Enforce cnonstraint that start date <= end date
    CHECK (valid_period_start <= valid_period_end)
);

CREATE TABLE issued_coupon (
    user_id INTEGER REFERENCES users(id),
    coupon_id INTEGER REFERENCES coupon_batch(id),
    PRIMARY KEY (user_id, coupon_id)
);

-- Combines Order, Places, Applies
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
     -- Enforce Key+TP constraint
    user_id INTEGER REFERENCES users(id) NOT NULL,
    coupon_id INTEGER,
    shipping_address TEXT,
    payment_amount NUMERIC,
    -- Enforce constraint that user can only use a coupon that was issued to them
    FOREIGN KEY (user_id, coupon_id) REFERENCES issued_coupon(user_id, coupon_id),
    -- Enforce constraint that a particular issued coupon can only be applied once
    UNIQUE (user_id, coupon_id)
);

CREATE TYPE orderline_status AS ENUM (
    'being_processed', 
    'shipped', 
    'delivered'
);

-- Rename Involves to Orderline
CREATE TABLE orderline (
    order_id INTEGER REFERENCES orders(id),
    shop_id INTEGER,
    product_id INTEGER,
    sell_timestamp TIMESTAMP,
    quantity INTEGER,
    shipping_cost NUMERIC,
    status orderline_status,
    delivery_date DATE,
    FOREIGN KEY (shop_id, product_id, sell_timestamp) REFERENCES sells(shop_id, product_id, sell_timestamp),
    PRIMARY KEY (order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that delivery date is null when being_processed, and not null otherwise
    CHECK ((status = 'being_processed' AND delivery_date IS NULL) OR (status <> 'being_processed' AND delivery_date IS NOT NULL))
);

-- Combines Comment, Makes
CREATE TABLE comment (
    id SERIAL PRIMARY KEY,
    -- Enforce Key+TP constraint
    user_id INTEGER REFERENCES users(id) NOT NULL
);

-- Combines Review, On
CREATE TABLE review (
    id INTEGER PRIMARY KEY REFERENCES comment(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that a particular product purchase can only be reviewed once
    UNIQUE (order_id, shop_id, product_id, sell_timestamp)
);

-- Combines ReviewVersion, HasReviewVersion
CREATE TABLE review_version (
    review_id INTEGER REFERENCES review ON DELETE CASCADE,
    review_timestamp TIMESTAMP,
    content TEXT,
    rating INTEGER,
    PRIMARY KEY (review_id, review_timestamp),
    -- Enforce range of values for rating
    CHECK (1 <= rating AND rating <= 5)
);

-- Combines Reply, To
CREATE TABLE reply (
    id INTEGER PRIMARY KEY REFERENCES comment(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    other_comment_id INTEGER REFERENCES comment(id) NOT NULL
);

-- Combines Reply_Version, HasReplyVersion
CREATE TABLE reply_version (
    reply_id INTEGER REFERENCES reply ON DELETE CASCADE,
    reply_timestamp TIMESTAMP,
    content TEXT,
    PRIMARY KEY (reply_id, reply_timestamp)
);

CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name TEXT,
    salary NUMERIC
);

CREATE TYPE refund_status AS ENUM (
    'pending',
    'being_handled',
    'accepted',
    'rejected'
);

-- Combines RefundRequest, HandlesRefund, For
CREATE TABLE refund_request (
    id SERIAL PRIMARY KEY,
    -- Enforce key constraint
    handled_by INTEGER REFERENCES employee(id),
    -- Enforce key + tp constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    quantity INTEGER,
    request_date DATE,
    status refund_status,
    handled_date DATE,
    rejection_reason TEXT,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that refund is accepted/rejected after the request is made
    CHECK (handled_date >= request_date),
    -- Enforce constraint that rejection reason should be null unless refund request is rejected
    CHECK ((status = 'rejected' AND rejection_reason IS NOT NULL) OR (status <> 'rejected' AND rejection_reason IS NULL)),
    -- Enforce constraint that refund handled_date should be null unless refund is handled
    CHECK (((status = 'pending' OR status = 'being_handled') AND handled_date IS NULL) OR ((status = 'accepted' OR status = 'rejected') AND handled_date IS NOT NULL)),
    -- Enforce constraint that refund handled_by should be null if status is pending, and non-null otherwise
    CHECK (((status = 'pending' AND handled_by IS NULL) OR (status <> 'pending' AND handled_by IS NOT NULL)))
);

CREATE TYPE complaint_status AS ENUM (
    'pending',
    'being_handled',
    'addressed'
);

-- Combines Complaint, HandlesComplaint, Files
CREATE TABLE complaint (
    id SERIAL PRIMARY KEY,
    content TEXT,
    status complaint_status,
    user_id INTEGER REFERENCES users(id),
    -- Enforce key constraint
    handled_by INTEGER REFERENCES employee(id),
    -- Enforce valid values for status and handled_by
    CHECK ((status = 'pending' AND handled_by IS NULL) OR (status <> 'pending' AND handled_by IS NOT NULL))
);

-- Combines ShopComplaint, ConcernsShop
CREATE TABLE shop_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    shop_id INTEGER REFERENCES shop(id) NOT NULL
);

-- Combines CommentComplaint, ConcernsComment
CREATE TABLE comment_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    comment_id INTEGER REFERENCES comment(id) NOT NULL
);

-- Combines DeliveryComplaint, ConcernsDelivery
CREATE TABLE delivery_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp)
);


/* ================================================= Triggers ================================================= */

-- To check if store is selling at least one product


CREATE OR REPLACE FUNCTION check_shop_products()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM sells WHERE shop_id = NEW.id) < 1 THEN
        RAISE EXCEPTION 'ERROR: SHOP DOES NOT HAVE PRODUCTS, CANCELLING PROCESS...';
    END IF;

    RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_shop_products_trigger
AFTER INSERT ON shop
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE PROCEDURE check_shop_products();



-- To check if order contains at least one product
CREATE OR REPLACE FUNCTION check_order()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM orderline WHERE order_id = NEW.id) < 1 THEN
        RAISE EXCEPTION 'ERROR: ORDER DOES NOT HAVE PRODUCTS, CANCELLING PROCESS...';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER check_order_trigger
AFTER INSERT ON orders
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_order();



-- Check that coupon is applied on order that exceeds min order amount

CREATE OR REPLACE FUNCTION check_coupon_validity()
RETURNS TRIGGER AS $$
DECLARE
    min_spending NUMERIC;
    current_spending NUMERIC;
BEGIN
    -- assume that user does have the coupon
    SELECT COALESCE(min_order_amount, 0) INTO min_spending 
    FROM coupon_batch
    WHERE coupon.id = NEW.coupon_id;

    SELECT COALESCE(SUM(orderline.quantity * sells.price), 0) INTO current_spending
    FROM orderline LEFT JOIN sells ON (orderline.shop_id = sells.shop_id AND orderline.product_id = sells.product_id AND orderline.sell_timestamp = sells.sell_timestamp)
    WHERE orderline.order_id = NEW.id;

    IF current_spending < min_spending THEN
        RAISE EXCEPTION 'ERROR: COUPON CANNOT BE APPLIED ON ORDER THAT EXCEEDS MIN ORDER AMOUNT.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER check_coupon_validity_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_coupon_validity();



-- check refund eligibility
CREATE OR REPLACE FUNCTION check_refund_eligibility()
RETURNS TRIGGER AS $$
DECLARE
    delivered_date DATE;
    refunded_quantity_quota INT;
    requested_refund_quantity INT;
BEGIN
    SELECT quantity INTO refunded_quantity_quota
    FROM orderline
    WHERE (order_id, shop_id, product_id, sell_timestamp) = (NEW.order_id, NEW.shop_id, NEW.product_id, NEW.sell_timestamp);

    SELECT SUM(quantity) INTO requested_refund_quantity
    FROM refund_request
    WHERE (order_id, shop_id, product_id, sell_timestamp) = (NEW.order_id, NEW.shop_id, NEW.product_id, NEW.sell_timestamp) AND status <> 'rejected';

    SELECT delivery_date INTO delivered_date
    FROM orderline
    WHERE (order_id, shop_id, product_id, sell_timestamp) = (NEW.order_id, NEW.shop_id, NEW.product_id, NEW.sell_timestamp) AND status = 'delivered';

    IF ((purchase_date IS NULL) OR (purchase_date + 30 < NEW.date)) THEN
        RAISE EXCEPTION 'ERROR: REFUND CANNOT BE APPLIED ON ORDER THAT WAS NOT DELIVERED MORE THAN 30 DAYS AGO.';
    ELSEIF (refunded_quantity_quota - requested_refund_quantity < NEW.quantity) THEN
        RAISE EXCEPTION 'ERROR: REFUND QUANTITY REQUESTED EXCEEDS QUANTITY OF PRODUCT ORDERED.';
    END IF;
    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_refund_eligibility_trigger
BEFORE INSERT ON refund_request
FOR EACH ROW EXECUTE PROCEDURE check_refund_eligibility();



-- check comment
CREATE OR REPLACE FUNCTION check_comment_func()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.id NOT IN (SELECT id FROM review) AND NEW.id NOT IN (SELECT id FROM reply)) THEN
		RAISE EXCEPTION 'ERROR: COMMENT NEEDS TO BE REPLY OR REVIEW.';
	ELSIF (NEW.id IN (SELECT id FROM review))
	AND (SELECT COUNT(*) FROM review_version WHERE review_version.review_id = NEW.id) < 1 THEN
		RAISE EXCEPTION 'ERROR: REVIEW DOES NOT HAVE REVIEW HISTORY.';
	ELSIF (NEW.id IN (SELECT id FROM reply))
	AND (SELECT COUNT(*) FROM reply_version WHERE reply_version.reply_id = NEW.id) < 1 THEN
		RAISE EXCEPTION 'ERRORL REPLY DOES NOT HAVE REPLY HISTORY.';
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_comment_trigger
AFTER INSERT ON comment
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_comment_func();



--check comment
CREATE OR REPLACE FUNCTION check_review_func()
RETURNS TRIGGER AS $$
DECLARE
	temp_id INT := 0;
BEGIN
	SELECT user_id INTO temp_id FROM comment
	WHERE comment.id = NEW.id;
	
	IF NEW.id IN (SELECT id from reply) THEN
		RAISE EXCEPTION 'ERROR: REVIEW CANNOT BE A REPLY.';
	ELSIF (ROW (NEW.shop_id, NEW.product_id, NEW.sell_timestamp) NOT IN (
		SELECT shop_id, product_id, sell_timestamp
		FROM orderline INNER JOIN orders ON (orderline.order_id = orders.id)
		WHERE orders.user_id = temp_id
	)) THEN 
		RAISE EXCEPTION 'ERROR: REVIEW CANNOT BE MADE ON PRODUCT THAT WAS NOT PURCHASED.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_review_trigger
BEFORE INSERT ON review
FOR EACH ROW EXECUTE FUNCTION check_review_func();




--check reply
CREATE OR REPLACE FUNCTION check_reply_func() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id IN (SELECT id from review) THEN
		RAISE EXCEPTION 'ERROR: REPLY CANNOT BE A REVIEW.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_reply_trigger
BEFORE INSERT ON reply
FOR EACH ROW EXECUTE FUNCTION check_reply_func();



-- check delivery complaints prereqs -> needs to be delivered first
CREATE OR REPLACE FUNCTION check_delivery_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.id NOT IN (
        	SELECT id
        	FROM orderline
        	WHERE (order_id, shop_id, product_id, sell_timestamp) = (NEW.order_id, NEW.shop_id, NEW.product_id, NEW.sell_timestamp)
        	AND status = 'delivered')) THEN
        RAISE EXCEPTION 'ERROR: DELIVERY COMPLAINT CANNOT BE MADE ON ORDER THAT HAS NOT BEEN DELIVERED.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_delivery_status_trigger
BEFORE INSERT ON delivery_complaint
FOR EACH ROW EXECUTE PROCEDURE check_delivery_status();



-- check that complaint is either delivery, shop-related or comment related
CREATE OR REPLACE FUNCTION check_complaint_type()
RETURNS TRIGGER AS $$
DECLARE
	delivery_count INT = 0;
	shop_count INT = 0;
	comment_count INT = 0;
BEGIN
    SELECT COUNT(*) INTO delivery_count FROM delivery_complaint WHERE id = NEW.id;
    SELECT COUNT(*) INTO shop_count FROM shop_complaint WHERE id = NEW.id;
    SELECT COUNT(*) INTO comment_count FROM comment_complaint WHERE id = NEW.id;
	
	IF (COALESCE(delivery_count + shop_count + comment_count, 0) <> 1) THEN
        RAISE EXCEPTION 'ERROR: COMPLAINT MUST BE ONLY ONE OF FOLLOWING TYPES: TYPE DELIVERY, SHOP-RELATED OR COMMENT-RELATED.';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_complaint_type_trigger
AFTER INSERT ON delivery_complaint
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_complaint_type();