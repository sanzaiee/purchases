﻿-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--
EXECUTE dbo.drop_schema 'purchase';
GO
CREATE SCHEMA purchase;
GO


--TODO: CREATE UNIQUE INDEXES

CREATE TABLE purchase.price_types
(
    price_type_id                           integer IDENTITY PRIMARY KEY,
    price_type_code                         national character varying(24) NOT NULL,
    price_type_name                         national character varying(500) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE UNIQUE INDEX price_types_price_type_code_uix
ON purchase.price_types(price_type_code)
WHERE deleted = 0;

CREATE UNIQUE INDEX price_types_price_type_name_uix
ON purchase.price_types(price_type_name)
WHERE deleted = 0;

CREATE TABLE purchase.item_cost_prices
(   
    item_cost_price_id                      bigint IDENTITY PRIMARY KEY,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    supplier_id                             integer REFERENCES inventory.suppliers,
    lead_time_in_days                       integer NOT NULL DEFAULT(0),
    includes_tax                            bit NOT NULL
                                            CONSTRAINT item_cost_prices_includes_tax_df   
                                            DEFAULT(0),
    price                                   decimal(30, 6) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE UNIQUE INDEX item_cost_prices_item_id_unit_id_supplier_id
ON purchase.item_cost_prices(item_id, unit_id, supplier_id)
WHERE deleted = 0;

CREATE TABLE purchase.purchases
(
    purchase_id                             bigint IDENTITY PRIMARY KEY,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                            integer NOT NULL REFERENCES purchase.price_types
);


CREATE TABLE purchase.purchase_returns
(
    purchase_return_id                      bigint IDENTITY PRIMARY KEY,
    purchase_id                             bigint NOT NULL REFERENCES purchase.purchases,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers   
);


CREATE TABLE purchase.quotations
(
    quotation_id                            bigint IDENTITY PRIMARY KEY,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETUTCDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                    national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.quotation_details
(
    quotation_detail_id                     bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
    discount_rate                           decimal(30, 6) NOT NULL DEFAULT(0),    
    tax                                     decimal(30, 6) NOT NULL DEFAULT(0),    
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);


CREATE TABLE purchase.orders
(
    order_id                                bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETUTCDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.order_details
(
    order_detail_id                         bigint IDENTITY PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES purchase.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
    discount_rate                           decimal(30, 6) NOT NULL DEFAULT(0),    
    tax                                     decimal(30, 6) NOT NULL DEFAULT(0),    
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);

CREATE TABLE purchase.supplier_payments
(
    payment_id                              bigint IDENTITY PRIMARY KEY,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    er_debit                                numeric(30, 6) NOT NULL,
    er_credit                               numeric(30, 6) NOT NULL,
    cash_repository_id                      integer NULL REFERENCES finance.cash_repositories,
    posted_date                             date NULL,
    tender                                  numeric(30, 6),
    change                                  numeric(30, 6),
    amount                                  numeric(30, 6),
    bank_id					                integer REFERENCES finance.bank_accounts,
	bank_instrument_code			        national character varying(500),
	bank_transaction_code			        national character varying(500),
	check_number                            national character varying(100),
    check_date                              date,
    check_bank_name                         national character varying(1000),
    check_amount                            numeric(30, 6)
);

CREATE INDEX supplier_payments_transaction_master_id_inx
ON purchase.supplier_payments(transaction_master_id);

CREATE INDEX supplier_payments_supplier_id_inx
ON purchase.supplier_payments(supplier_id);

CREATE INDEX supplier_payments_currency_code_inx
ON purchase.supplier_payments(currency_code);

CREATE INDEX supplier_payments_cash_repository_id_inx
ON purchase.supplier_payments(cash_repository_id);

CREATE INDEX supplier_payments_posted_date_inx
ON purchase.supplier_payments(posted_date);

CREATE TYPE purchase.purchase_detail_type
AS TABLE
(
    store_id            integer,
    transaction_type    national character varying(2),
    item_id             integer,
    quantity            decimal(30, 6),
    unit_id             integer,
    price               decimal(30, 6),
    discount_rate       decimal(30, 6),
    tax                 decimal(30, 6),
    shipping_charge     decimal(30, 6)
);



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_item_cost_price.sql --<--<--
IF OBJECT_ID('purchase.get_item_cost_price') IS NOT NULL
DROP FUNCTION purchase.get_item_cost_price;

GO

CREATE FUNCTION purchase.get_item_cost_price(@item_id integer, @supplier_id bigint, @unit_id integer)
RETURNS decimal(30, 6)
AS  
BEGIN
    DECLARE @price              decimal(30, 6);
    DECLARE @costing_unit_id    integer;
    DECLARE @factor             decimal(30, 6);

    --Fist pick the catalog price which matches all these fields:
    --Item, Customer Type, Price Type, and Unit.
    --This is the most effective price.
    SELECT 
        @price = purchase.item_cost_prices.price, 
        @costing_unit_id = purchase.item_cost_prices.unit_id
    FROM purchase.item_cost_prices
    WHERE purchase.item_cost_prices.item_id = @item_id
    AND purchase.item_cost_prices.supplier_id = @supplier_id
    AND purchase.item_cost_prices.unit_id = @unit_id
    AND purchase.item_cost_prices.deleted = 0;


    IF(@costing_unit_id IS NULL)
    BEGIN
        --We do not have a cost price of this item for the unit supplied.
        --Let's see if this item has a price for other units.
        SELECT 
            @price = purchase.item_cost_prices.price, 
            @costing_unit_id = purchase.item_cost_prices.unit_id
        FROM purchase.item_cost_prices
        WHERE purchase.item_cost_prices.item_id = @item_id
        AND purchase.item_cost_prices.supplier_id = @supplier_id
        AND purchase.item_cost_prices.deleted = 0;
    END;

    
    IF(@price IS NULL)
    BEGIN
        --This item does not have cost price defined in the catalog.
        --Therefore, getting the default cost price from the item definition.
        SELECT 
            @price = cost_price, 
            @costing_unit_id = unit_id
        FROM inventory.items
        WHERE inventory.items.item_id = @item_id
        AND inventory.items.deleted = 0;
    END;

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    SET @factor = inventory.convert_unit(@unit_id, @costing_unit_id);
    RETURN @price * @factor;
END;



--SELECT * FROM purchase.get_item_cost_price(6, 1, 7);


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_order_view.sql --<--<--
IF OBJECT_ID('purchase.get_order_view') IS NOT NULL
DROP FUNCTION purchase.get_order_view;

GO

CREATE FUNCTION purchase.get_order_view
(
    @user_id                        integer,
    @office_id                      integer,
    @supplier                       national character varying(500),
    @from                           date,
    @to                             date,
    @expected_from                  date,
    @expected_to                    date,
    @id                             bigint,
    @reference_number               national character varying(500),
    @internal_memo                  national character varying(500),
    @terms                          national character varying(500),
    @posted_by                      national character varying(500),
    @office                         national character varying(500)
)
RETURNS @result TABLE
(
    id                              bigint,
    supplier                        national character varying(500),
    value_date                      date,
    expected_date                   date,
    reference_number                national character varying(24),
    terms                           national character varying(500),
    internal_memo                   national character varying(500),
    posted_by                       national character varying(500),
    office                          national character varying(500),
    transaction_ts                  DATETIMEOFFSET
)
AS

BEGIN
    WITH office_cte(office_id) AS 
    (
        SELECT @office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    INSERT INTO @result
    SELECT 
        purchase.orders.order_id,
        inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id),
        purchase.orders.value_date,
        purchase.orders.expected_delivery_date,
        purchase.orders.reference_number,
        purchase.orders.terms,
        purchase.orders.internal_memo,
        account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
        core.get_office_name_by_office_id(office_id) AS office,
        purchase.orders.transaction_timestamp
    FROM purchase.orders
    WHERE 1 = 1
    AND purchase.orders.value_date BETWEEN @from AND @to
    AND purchase.orders.expected_delivery_date BETWEEN @expected_from AND @expected_to
    AND purchase.orders.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(@id, 0) = 0 OR @id = purchase.orders.order_id)
    AND COALESCE(LOWER(purchase.orders.reference_number), '') LIKE '%' + LOWER(@reference_number) + '%' 
    AND COALESCE(LOWER(purchase.orders.internal_memo), '') LIKE '%' + LOWER(@internal_memo) + '%' 
    AND COALESCE(LOWER(purchase.orders.terms), '') LIKE '%' + LOWER(@terms) + '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.orders.supplier_id)) LIKE '%' + LOWER(@supplier) + '%' 
    AND LOWER(account.get_name_by_user_id(purchase.orders.user_id)) LIKE '%' + LOWER(@posted_by) + '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.orders.office_id)) LIKE '%' + LOWER(@office) + '%' 
    AND purchase.orders.deleted = 0;

    RETURN;
END;




--SELECT * FROM purchase.get_order_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_code.sql --<--<--
IF OBJECT_ID('purchase.get_price_type_id_by_price_type_code') IS NOT NULL
DROP FUNCTION purchase.get_price_type_id_by_price_type_code;

GO

CREATE FUNCTION purchase.get_price_type_id_by_price_type_code(@price_type_code national character varying(24))
RETURNS integer
AS
BEGIN
    RETURN
    (
	    SELECT purchase.price_types.price_type_id
	    FROM purchase.price_types
	    WHERE purchase.price_types.price_type_code = @price_type_code
    );
END



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_name.sql --<--<--
IF OBJECT_ID('purchase.get_price_type_id_by_price_type_name') IS NOT NULL
DROP FUNCTION purchase.get_price_type_id_by_price_type_name;

GO

CREATE FUNCTION purchase.get_price_type_id_by_price_type_name(@price_type_name national character varying(24))
RETURNS integer
AS

BEGIN
    RETURN
    (
	    SELECT purchase.price_types.price_type_id
	    FROM purchase.price_types
	    WHERE purchase.price_types.price_type_name = @price_type_name
    );
END;

GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_quotation_view.sql --<--<--
IF OBJECT_ID('purchase.get_quotation_view') IS NOT NULL
DROP FUNCTION purchase.get_quotation_view;

GO

CREATE FUNCTION purchase.get_quotation_view
(
    @user_id                        integer,
    @office_id                      integer,
    @supplier                       national character varying(500),
    @from                           date,
    @to                             date,
    @expected_from                  date,
    @expected_to                    date,
    @id                             bigint,
    @reference_number               national character varying(500),
    @internal_memo                  national character varying(500),
    @terms                          national character varying(500),
    @posted_by                      national character varying(500),
    @office                         national character varying(500)
)
RETURNS @result TABLE
(
    id                              bigint,
    supplier                        national character varying(500),
    value_date                      date,
    expected_date                   date,
    reference_number                national character varying(24),
    terms                           national character varying(500),
    internal_memo                   national character varying(500),
    posted_by                       national character varying(500),
    office                          national character varying(500),
    transaction_ts                  DATETIMEOFFSET
)
AS

BEGIN
    WITH office_cte(office_id) AS 
    (
        SELECT @office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    INSERT INTO @result
    SELECT 
        purchase.quotations.quotation_id,
        inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id),
        purchase.quotations.value_date,
        purchase.quotations.expected_delivery_date,
        purchase.quotations.reference_number,
        purchase.quotations.terms,
        purchase.quotations.internal_memo,
        account.get_name_by_user_id(purchase.quotations.user_id) AS posted_by,
        core.get_office_name_by_office_id(office_id) AS office,
        purchase.quotations.transaction_timestamp
    FROM purchase.quotations
    WHERE 1 = 1
    AND purchase.quotations.value_date BETWEEN @from AND @to
    AND purchase.quotations.expected_delivery_date BETWEEN @expected_from AND @expected_to
    AND purchase.quotations.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(@id, 0) = 0 OR @id = purchase.quotations.quotation_id)
    AND COALESCE(LOWER(purchase.quotations.reference_number), '') LIKE '%' + LOWER(@reference_number) + '%' 
    AND COALESCE(LOWER(purchase.quotations.internal_memo), '') LIKE '%' + LOWER(@internal_memo) + '%' 
    AND COALESCE(LOWER(purchase.quotations.terms), '') LIKE '%' + LOWER(@terms) + '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.quotations.supplier_id)) LIKE '%' + LOWER(@supplier) + '%' 
    AND LOWER(account.get_name_by_user_id(purchase.quotations.user_id)) LIKE '%' + LOWER(@posted_by) + '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.quotations.office_id)) LIKE '%' + LOWER(@office) + '%' 
    AND purchase.quotations.deleted = 0;

    RETURN;
END;




--SELECT * FROM purchase.get_quotation_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_supplier_id_by_supplier_code.sql --<--<--
IF OBJECT_ID('purchase.get_supplier_id_by_supplier_code') IS NOT NULL
DROP FUNCTION purchase.get_supplier_id_by_supplier_code;

GO

CREATE FUNCTION purchase.get_supplier_id_by_supplier_code(@supplier_code national character varying(24))
RETURNS bigint
AS

BEGIN
    RETURN
    (
		SELECT supplier_id
		FROM inventory.suppliers
		WHERE inventory.suppliers.supplier_code=@supplier_code
		AND inventory.suppliers.deleted = 0
    );
END;





GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.post_purchase.sql --<--<--
IF OBJECT_ID('purchase.post_purchase') IS NOT NULL
DROP PROCEDURE purchase.post_purchase;

GO


CREATE PROCEDURE purchase.post_purchase
(
    @office_id                              integer,
    @user_id                                integer,
    @login_id                               bigint,
    @value_date                             date,
    @book_date                              date,
    @cost_center_id                         integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @details                                purchase.purchase_detail_type READONLY,
	@transaction_master_id					bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @checkout_id                    bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @shipping_address_id            integer;
    DECLARE @grand_total                    decimal(30, 6);
    DECLARE @discount_total                 decimal(30, 6);
    DECLARE @payable                        decimal(30, 6);
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code               national character varying(50);
    DECLARE @tax_total                      decimal(30, 6);
    DECLARE @tax_account_id                 integer;
    DECLARE @shipping_charge                decimal(30, 6);
    DECLARE @book_name                      national character varying(100) = 'Purchase';

    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);

    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        store_id                            integer,
        transaction_type                    national character varying(2),
        item_id                             integer, 
        quantity                            decimal(30, 6),
        unit_id                             integer,
        base_quantity                       decimal(30, 6),
        base_unit_id                        integer,
        price                               decimal(30, 6) NOT NULL DEFAULT(0),
        cost_of_goods_sold                  decimal(30, 6) NOT NULL DEFAULT(0),
        discount_rate                       decimal(30, 6),
        discount                            decimal(30, 6) NOT NULL DEFAULT(0),
        tax                                 decimal(30, 6) NOT NULL DEFAULT(0),
        shipping_charge                     decimal(30, 6) NOT NULL DEFAULT(0),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    );

    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               bigint, 
        tran_type                           national character varying(4), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  decimal(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  decimal(30, 6), 
        amount_in_local_currency            decimal(30, 6)
    );

    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction           = can_post_transaction,
            @error_message                  = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

        SET @tax_account_id                 = finance.get_sales_tax_account_id_by_office_id(@office_id);

        IF(@supplier_id IS NULL)
        BEGIN
            RAISERROR('Invalid supplier', 13, 1);
        END;
        



        INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge)
        SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge
        FROM @details;


        UPDATE @checkout_details 
        SET
            base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
            base_unit_id                    = inventory.get_root_unit_id(unit_id),
            purchase_account_id             = inventory.get_purchase_account_id(item_id),
            purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
            inventory_account_id            = inventory.get_inventory_account_id(item_id),
            discount                        = ROUND((price * quantity) * (discount_rate / 100), 2);
        
        IF EXISTS
        (
            SELECT TOP 1 0 FROM @checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
        )
        BEGIN
            RAISERROR('Item/unit mismatch.', 13, 1);
        END;

        SELECT @discount_total              = SUM(COALESCE(discount, 0)) FROM @checkout_details;
        SELECT @grand_total                 = SUM(COALESCE(price, 0) * COALESCE(quantity, 0)) FROM @checkout_details;
        SELECT @shipping_charge             = SUM(COALESCE(shipping_charge, 0)) FROM @checkout_details;
        SELECT @tax_total                   = SUM(COALESCE(tax, 0)) FROM @checkout_details;



        SET @payable                        = @grand_total - COALESCE(@discount_total, 0) + COALESCE(@shipping_charge, 0) + COALESCE(@tax_total, 0);
        SET @default_currency_code          = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter                   = finance.get_new_transaction_counter(@value_date);
        SET @transaction_code               = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

        IF(@is_periodic = 1)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
            FROM @checkout_details
            GROUP BY purchase_account_id;
        END
        ELSE
        BEGIN
            --Perpetutal Inventory Accounting System
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
            FROM @checkout_details
            GROUP BY inventory_account_id;
        END;


        IF(@discount_total > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
            FROM @checkout_details
            GROUP BY purchase_discount_account_id;
        END;

        IF(COALESCE(@tax_total, 0) > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
        END;    

        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @payable, 1, @default_currency_code, @payable;


        UPDATE @temp_transaction_details SET transaction_master_id = @transaction_master_id;        
        UPDATE @checkout_details SET checkout_id = @checkout_id;
        
        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
        SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;
        SET @transaction_master_id = SCOPE_IDENTITY();
        
        INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
        SELECT @value_date, @book_date, @office_id, @transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
        FROM @temp_transaction_details
        ORDER BY tran_type DESC;


        INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, shipper_id, office_id)
        SELECT @value_date, @book_date, @transaction_master_id, @book_name, @user_id, @shipper_id, @office_id;
        SET @checkout_id                = SCOPE_IDENTITY();

        INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
        SELECT @checkout_id, @supplier_id, @price_type_id;

        INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount, cost_of_goods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity)
        SELECT @checkout_id, @value_date, @book_date, store_id, transaction_type, item_id, price, discount, cost_of_goods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity
        FROM @checkout_details;
        

        EXECUTE finance.auto_verify @transaction_master_id, @office_id;

        IF(@tran_count = 0)
        BEGIN
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() <> 0 AND @tran_count = 0) 
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE @ErrorMessage national character varying(4000)  = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int                              = ERROR_SEVERITY();
        DECLARE @ErrorState int                                 = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

GO



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.post_return.sql --<--<--
IF OBJECT_ID('purchase.post_return') IS NOT NULL
DROP PROCEDURE purchase.post_return;

GO

CREATE PROCEDURE purchase.post_return
(
    @transaction_master_id                  bigint,
    @office_id                              integer,
    @user_id                                integer,
    @login_id                               bigint,
    @value_date                             date,
    @book_date                              date,
    @cost_center_id                         integer,
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @details                                purchase.purchase_detail_type READONLY,
    @tran_master_id                         bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @purchase_id                    bigint;
    DECLARE @original_price_type_id         integer;
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code				national character varying(50);
    DECLARE @checkout_id                    bigint;
    DECLARE @grand_total                    decimal(30, 6);
    DECLARE @discount_total                 decimal(30, 6);
    DECLARE @tax_total                      decimal(30, 6);
    DECLARE @credit_account_id              integer;
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @sm_id                          bigint;
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @book_name                      national character varying(1000)='Purchase Return';
    DECLARE @receivable                     decimal(30, 6);
    DECLARE @tax_account_id                 integer;
    DECLARE @total_rows                     integer = 0;
    DECLARE @counter                        integer = 0;
    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);
        
    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        transaction_type                    national character varying(2), 
        store_id                            integer,
        item_code                           national character varying(50),
        item_id                             integer, 
        quantity                            decimal(30, 6),
        unit_name                           national character varying(1000),
        unit_id                             integer,
        base_quantity                       decimal(30, 6),
        base_unit_id                        integer,                
        price                               decimal(30, 6),
        discount_rate                       decimal(30, 6),
        discount                            decimal(30, 6),
        tax                                 decimal(30, 6),
        shipping_charge                     decimal(30, 6),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    );

    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               BIGINT, 
        transaction_type                    national character varying(2), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  decimal(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  decimal(30, 6), 
        amount_in_local_currency            decimal(30, 6)
    );


    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction   = can_post_transaction,
            @error_message          = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

       
        SELECT @purchase_id = purchase.purchases.purchase_id
        FROM purchase.purchases
        INNER JOIN inventory.checkouts
        ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
        INNER JOIN finance.transaction_master
        ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
        WHERE finance.transaction_master.transaction_master_id = @transaction_master_id;

        SELECT @original_price_type_id = purchase.purchases.price_type_id
        FROM purchase.purchases
        WHERE purchase.purchases.purchase_id = @purchase_id;

        IF(@price_type_id != @original_price_type_id)
        BEGIN
            RAISERROR('Please select the right price type.', 13, 1);
        END;
        
        SELECT @sm_id = checkout_id 
        FROM inventory.checkouts 
        WHERE inventory.checkouts.transaction_master_id = @transaction_master_id
        AND inventory.checkouts.deleted = 0;

        INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge)
        SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge
        FROM @details;

        UPDATE @checkout_details 
        SET
            base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
            base_unit_id                    = inventory.get_root_unit_id(unit_id),
            purchase_account_id             = inventory.get_purchase_account_id(item_id),
            purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
            inventory_account_id            = inventory.get_inventory_account_id(item_id),
            discount                        = ROUND((price * quantity) * (discount_rate / 100), 2);

        IF EXISTS
        (
            SELECT TOP 1 0 FROM @checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
        )
        BEGIN
            RAISERROR('Item/unit mismatch.', 13, 1);
        END;

        
		SET @tax_account_id                     = finance.get_sales_tax_account_id_by_office_id(@office_id);
        SET @default_currency_code              = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter                       = finance.get_new_transaction_counter(@value_date);
        SET @transaction_code                   = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);
           
        SELECT @tax_total = SUM(COALESCE(tax, 0)) FROM @checkout_details;
        SELECT @discount_total = SUM(COALESCE(discount, 0)) FROM @checkout_details;
        SELECT @grand_total = SUM(COALESCE(price, 0) * COALESCE(quantity, 0)) FROM @checkout_details;

        SET @receivable = @grand_total + @tax_total - COALESCE(@discount_total, 0);


        IF(@is_periodic = 1)
        BEGIN
            INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
            FROM @checkout_details
            GROUP BY purchase_account_id;
        END
        ELSE
        BEGIN
            --Perpetutal Inventory Accounting System
            INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
            FROM @checkout_details
            GROUP BY inventory_account_id;
        END;


        IF(COALESCE(@discount_total, 0) > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
            FROM @checkout_details
            GROUP BY purchase_discount_account_id;
        END;

        IF(COALESCE(@tax_total, 0) > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
        END;

        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @receivable, 1, @default_currency_code, @receivable;




        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
        SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

        SET @tran_master_id = SCOPE_IDENTITY();

        UPDATE @temp_transaction_details
		SET transaction_master_id   = @tran_master_id;


        INSERT INTO finance.transaction_details(office_id, value_date, book_date, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
        SELECT @office_id, @value_date, @book_date, transaction_master_id, transaction_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
        FROM @temp_transaction_details
        ORDER BY transaction_type DESC;


        INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, office_id, shipper_id)
        SELECT @value_date, @book_date, @tran_master_id, @book_name, @user_id, @office_id, @shipper_id;
 
        SET @checkout_id = SCOPE_IDENTITY();

        UPDATE @checkout_details				
		SET checkout_id				= @checkout_id;
               
        INSERT INTO inventory.checkout_details(value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge)
        SELECT @value_date, @book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge
        FROM @checkout_details;

        INSERT INTO purchase.purchase_returns(checkout_id, purchase_id, supplier_id)
        SELECT @checkout_id, @purchase_id, @supplier_id;

        
        EXECUTE finance.auto_verify @transaction_master_id, @office_id;

        IF(@tran_count = 0)
        BEGIN
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() <> 0 AND @tran_count = 0) 
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE @ErrorMessage national character varying(4000)  = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int                              = ERROR_SEVERITY();
        DECLARE @ErrorState int                                 = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.post_supplier_payment.sql --<--<--
IF OBJECT_ID('purchase.post_supplier_payment') IS NOT NULL
DROP PROCEDURE purchase.post_supplier_payment;

GO

CREATE PROCEDURE purchase.post_supplier_payment
(
    @user_id                                    integer, 
    @office_id                                  integer, 
    @login_id                                   bigint,
    @supplier_id                                integer, 
    @currency_code                              national character varying(12),
    @cash_account_id                            integer,
    @amount                                     numeric(30, 6), 
    @exchange_rate_debit                        numeric(30, 6), 
    @exchange_rate_credit                       numeric(30, 6),
    @reference_number                           national character varying(24), 
    @statement_reference                        national character varying(128), 
    @cost_center_id                             integer,
    @cash_repository_id                         integer,
    @posted_date                                date,
    @bank_account_id                            integer,
    @bank_instrument_code                       national character varying(128),
    @bank_tran_code                             national character varying(128),
	@transaction_master_id						bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @value_date                         date = finance.get_value_date(@office_id);
    DECLARE @book_date                          date = @value_date;
    DECLARE @book                               national character varying(50);
    DECLARE @base_currency_code                 national character varying(12);
    DECLARE @local_currency_code                national character varying(12);
    DECLARE @supplier_account_id                integer;
    DECLARE @debit                              numeric(30, 6);
    DECLARE @credit                             numeric(30, 6);
    DECLARE @lc_debit                           numeric(30, 6);
    DECLARE @lc_credit                          numeric(30, 6);
    DECLARE @is_cash                            bit;
    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);

    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction   = can_post_transaction,
            @error_message          = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

		IF(@cash_repository_id > 0)
		BEGIN
			IF(@posted_date IS NOT NULL OR @bank_account_id IS NOT NULL OR COALESCE(@bank_instrument_code, '') != '' OR COALESCE(@bank_tran_code, '') != '')
			BEGIN
				RAISERROR('Invalid bank transaction information provided.', 16, 1);
			END;

			SET @is_cash = 1;
		END;

		SET @book                                   = 'Purchase Payment';    
		SET @supplier_account_id                    = inventory.get_account_id_by_supplier_id(@supplier_id);    
		SET @local_currency_code                    = core.get_currency_code_by_office_id(@office_id);
		SET @base_currency_code                     = inventory.get_currency_code_by_supplier_id(@supplier_id);

		IF(@local_currency_code = @currency_code AND @exchange_rate_debit != 1)
		BEGIN
			RAISERROR('Invalid exchange rate.', 16, 1);
		END;

		IF(@base_currency_code = @currency_code AND @exchange_rate_credit != 1)
		BEGIN
			RAISERROR('Invalid exchange rate.', 16, 1);
		END;
        
		SET @debit                                  = @amount;
		SET @lc_debit                               = @amount * @exchange_rate_debit;

		SET @credit                                 = @amount * (@exchange_rate_debit/ @exchange_rate_credit);
		SET @lc_credit                              = @amount * @exchange_rate_debit;
    
		INSERT INTO finance.transaction_master
		(
			transaction_counter, 
			transaction_code, 
			book, 
			value_date, 
			book_date, 
			user_id, 
			login_id, 
			office_id, 
			cost_center_id, 
			reference_number, 
			statement_reference
		)
		SELECT 
			finance.get_new_transaction_counter(@value_date), 
			finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id),
			@book,
			@value_date,
			@book_date,
			@user_id,
			@login_id,
			@office_id,
			@cost_center_id,
			@reference_number,
			@statement_reference;


		SET @transaction_master_id = SCOPE_IDENTITY();

		--Debit
		IF(@is_cash = 1)
		BEGIN
			INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
			SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Cr', @cash_account_id, @statement_reference, @cash_repository_id, @currency_code, @debit, @local_currency_code, @exchange_rate_debit, @lc_debit, @user_id;
		END
		ELSE
		BEGIN
			INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
			SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Cr', @bank_account_id, @statement_reference, NULL, @currency_code, @debit, @local_currency_code, @exchange_rate_debit, @lc_debit, @user_id;        
		END;

		--Credit
		INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
		SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Dr', @supplier_account_id, @statement_reference, NULL, @base_currency_code, @credit, @local_currency_code, @exchange_rate_credit, @lc_credit, @user_id;
    
    
		INSERT INTO purchase.supplier_payments(transaction_master_id, supplier_id, currency_code, amount, er_debit, er_credit, cash_repository_id, posted_date, bank_id, bank_instrument_code, bank_transaction_code)
		SELECT @transaction_master_id, @supplier_id, @currency_code, @amount,  @exchange_rate_debit, @exchange_rate_credit, @cash_repository_id, @posted_date, @bank_account_id, @bank_instrument_code, @bank_tran_code;

		EXECUTE finance.auto_verify @transaction_master_id, @office_id;

        IF(@tran_count = 0)
        BEGIN
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() <> 0 AND @tran_count = 0) 
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE @ErrorMessage national character varying(4000)  = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int                              = ERROR_SEVERITY();
        DECLARE @ErrorState int                                 = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

GO

--EXECUTE purchase.post_supplier_payment

--     1, --@user_id                                    integer, 
--     1, --@office_id                                  integer, 
--     1, --@login_id                                   bigint,
--     1, --@supplier_id                                integer, 
--     'USD', --@currency_code                              national character varying(12), 
--     1,--    @cash_account_id                            integer,
--     100, --@amount                                     numeric(30, 6), 
--     1, --@exchange_rate_debit                        numeric(30, 6), 
--     1, --@exchange_rate_credit                       numeric(30, 6),
--     '', --@reference_number                           national character varying(24), 
--     '', --@statement_reference                        national character varying(128), 
--     1, --@cost_center_id                             integer,
--     1, --@cash_repository_id                         integer,
--     NULL, --@posted_date                                date,
--     NULL, --@bank_account_id                            bigint,
--     NULL, -- @bank_instrument_code                       national character varying(128),
--     NULL, -- @bank_tran_code                             national character varying(128),
--	 NULL
--;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/03.menus/menus.sql --<--<--
DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM core.menus
WHERE app_name = 'MixERP.Purchases';


EXECUTE core.create_app 'MixERP.Purchases', 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL;

EXECUTE core.create_menu 'MixERP.Purchases', 'Tasks', 'Tasks', '', 'lightning', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseEntry', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierPayment', 'Supplier Payment', '/dashboard/purchase/tasks/payment', 'write', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseReturns', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseQuotations', 'Purchase Quotations', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseOrders', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file national character varying(1000) outline', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseVerification', 'PurchaseVerification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierPaymentVerification', 'Supplier Payment Verification', '/dashboard/purchase/tasks/payment/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseReturnVerification', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks';

EXECUTE core.create_menu 'MixERP.Purchases', 'Setup', 'Setup', 'square outline', 'configure', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'Suppliers', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup';
EXECUTE core.create_menu 'MixERP.Purchases', 'PriceTypes', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup';
EXECUTE core.create_menu 'MixERP.Purchases', 'CostPrices', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup';

EXECUTE core.create_menu 'MixERP.Purchases', 'Reports', 'Reports', '', 'block layout', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'AccountPayables', 'Account Payables', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayables.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'TopSuppliers', 'Top Suppliers', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/TopSuppliers.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'LowInventoryProducts', 'Low Inventory Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/LowInventory.xml', 'warning', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'OutOfStockProducts', 'Out of Stock Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/OutOfStock.xml', 'remove circle', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierContacts', 'Supplier Contacts', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/SupplierContacts.xml', 'remove circle', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseSummary', 'Purchase Summary', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseSummary.xml', 'grid layout icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseDiscountStatus', 'Purchase Discount Status', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseDiscountStatus.xml', 'shopping basket icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PaymentJournalSummary', 'Payment Journal Summary Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PaymentJournalSummary.xml', 'angle double right icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'AccountPayableVendor', 'Account Payable Vendor Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayableVendor.xml', 'external share icon', 'Reports';

DECLARE @office_id integer = core.get_office_id_by_office_name('Default');
EXECUTE auth.create_app_menu_policy
'Admin', 
@office_id, 
'MixERP.Purchases',
'{*}';



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/04.default-values/01.default-values.sql --<--<--
INSERT INTO purchase.price_types(price_type_code, price_type_name)
SELECT 'RET',   'Retail' UNION ALL
SELECT 'WHO',   'Wholesale';


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/05.reports/purchase.get_account_payables_report.sql --<--<--
IF OBJECT_ID('purchase.get_account_payables_report') IS NOT NULL
DROP FUNCTION purchase.get_account_payables_report;

GO

CREATE FUNCTION purchase.get_account_payables_report(@office_id integer, @from date)
RETURNS @results TABLE
(
    office_id                   integer,
    office_name                 national character varying(500),
    account_id                  integer,
    account_number              national character varying(24),
    account_name                national character varying(500),
    previous_period             numeric(30, 6),
    current_period              numeric(30, 6),
    total_amount                numeric(30, 6)
)
AS
BEGIN
    INSERT INTO @results(account_id, office_name, office_id)
    SELECT DISTINCT inventory.suppliers.account_id, core.get_office_name_by_office_id(@office_id), @office_id FROM inventory.suppliers;


    UPDATE @results
    SET
        account_number  = finance.accounts.account_number,
        account_name    = finance.accounts.account_name
    FROM @results AS results
	INNER JOIN finance.accounts
    ON finance.accounts.account_id = results.account_id;


    UPDATE @results
    SET previous_period = 
    (        
        SELECT 
            SUM
            (
                CASE WHEN finance.verified_transaction_view.tran_type = 'Cr' THEN
                finance.verified_transaction_view.amount_in_local_currency
                ELSE
                finance.verified_transaction_view.amount_in_local_currency * -1
                END                
            ) AS amount
        FROM finance.verified_transaction_view
        WHERE finance.verified_transaction_view.value_date < @from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(@office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    )
	FROM @results  results;


    UPDATE @results
    SET current_period = 
    (        
        SELECT 
            SUM
            (
                CASE WHEN finance.verified_transaction_view.tran_type = 'Cr' THEN
                finance.verified_transaction_view.amount_in_local_currency
                ELSE
                finance.verified_transaction_view.amount_in_local_currency * -1
                END                
            ) AS amount
        FROM finance.verified_transaction_view
        WHERE finance.verified_transaction_view.value_date >= @from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(@office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    ) FROM @results AS results;

    UPDATE @results
    SET total_amount = COALESCE(results.previous_period, 0) + COALESCE(results.current_period, 0)
	FROM @results AS results;

	DELETE FROM @results
	WHERE COALESCE(previous_period, 0) = 0
	AND COALESCE(current_period, 0) = 0
	AND COALESCE(total_amount, 0) = 0;
    
    RETURN;
END

GO

--SELECT * FROM purchase.get_account_payables_report(1, '1-1-2000');



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/05.scrud-views/purchase.item_cost_price_scrud_view.sql --<--<--
IF OBJECT_ID('purchase.item_cost_price_scrud_view') IS NOT NULL
DROP VIEW purchase.item_cost_price_scrud_view;

GO



CREATE VIEW purchase.item_cost_price_scrud_view
AS
SELECT
    purchase.item_cost_prices.item_cost_price_id,
    purchase.item_cost_prices.item_id,
    inventory.items.item_code + ' (' + inventory.items.item_name + ')' AS item,
    purchase.item_cost_prices.unit_id,
    inventory.units.unit_code + ' (' + inventory.units.unit_name + ')' AS unit,
    purchase.item_cost_prices.supplier_id,
    inventory.suppliers.supplier_code + ' (' + inventory.suppliers.supplier_name + ')' AS supplier,
    purchase.item_cost_prices.lead_time_in_days,
    purchase.item_cost_prices.includes_tax,
    purchase.item_cost_prices.price
FROM purchase.item_cost_prices
INNER JOIN inventory.items
ON inventory.items.item_id = purchase.item_cost_prices.item_id
INNER JOIN inventory.units
ON inventory.units.unit_id = purchase.item_cost_prices.unit_id
INNER JOIN inventory.suppliers
ON inventory.suppliers.supplier_id = purchase.item_cost_prices.supplier_id
WHERE purchase.item_cost_prices.deleted = 0;


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/05.views/purchase.item_view.sql --<--<--
IF OBJECT_ID('purchase.item_view') IS NOT NULL
DROP VIEW purchase.item_view;

GO



CREATE VIEW purchase.item_view
AS
SELECT
    inventory.items.item_id,
    inventory.items.item_code,
    inventory.items.item_name,
    inventory.items.is_taxable_item,
    inventory.items.barcode,
    inventory.items.item_group_id,
    inventory.item_groups.item_group_name,
    inventory.item_types.item_type_id,
    inventory.item_types.item_type_name,
    inventory.items.brand_id,
    inventory.brands.brand_name,
    inventory.items.preferred_supplier_id,
    inventory.items.unit_id,
    inventory.get_associated_unit_list_csv(inventory.items.unit_id) AS valid_units,
    inventory.units.unit_code,
    inventory.units.unit_name,
    inventory.items.hot_item,
    inventory.items.cost_price,
    inventory.items.cost_price_includes_tax,
    inventory.items.photo
FROM inventory.items
INNER JOIN inventory.item_groups
ON inventory.item_groups.item_group_id = inventory.items.item_group_id
INNER JOIN inventory.item_types
ON inventory.item_types.item_type_id = inventory.items.item_type_id
INNER JOIN inventory.brands
ON inventory.brands.brand_id = inventory.items.brand_id
INNER JOIN inventory.units
ON inventory.units.unit_id = inventory.items.unit_id
WHERE inventory.items.deleted = 0
AND inventory.items.allow_purchase = 1
AND inventory.items.maintain_inventory = 1;

GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/99.ownership.sql --<--<--
EXEC sp_addrolemember  @rolename = 'db_owner', @membername  = 'frapid_db_user'


EXEC sp_addrolemember  @rolename = 'db_datareader', @membername  = 'report_user'


GO


DECLARE @proc sysname
DECLARE @cmd varchar(8000)

DECLARE cur CURSOR FOR 
SELECT '[' + schema_name(schema_id) + '].[' + name + ']' FROM sys.objects
WHERE type IN('FN')
AND is_ms_shipped = 0
ORDER BY 1
OPEN cur
FETCH next from cur into @proc
WHILE @@FETCH_STATUS = 0
BEGIN
     SET @cmd = 'GRANT EXEC ON ' + @proc + ' TO report_user';
     EXEC (@cmd)

     FETCH next from cur into @proc
END
CLOSE cur
DEALLOCATE cur

GO

