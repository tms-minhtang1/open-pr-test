from src.checkout import DEFAULT_TAX_RATE, average_item_price, checkout


def test_average_item_price_is_per_unit_not_per_line():
    items = [{"name": "mug", "price": 500, "quantity": 5}]
    assert average_item_price(items) == 500


def test_average_item_price_of_empty_cart_is_zero():
    assert average_item_price([]) == 0


def test_two_coupons_compound_to_nineteen_percent():
    items = [{"name": "mug", "price": 10000, "quantity": 1}]
    # 10000 - 19% = 8100, plus the default 10% tax.
    assert checkout(items, 10, applied_coupons=[10], tax_rate=0) == 8100
    assert checkout(items, 10, applied_coupons=[10]) == 8910


def test_checkout_over_an_empty_cart_charges_nothing():
    assert checkout([], 10) == 0


def test_half_a_cent_rounds_up_not_to_even():
    items = [{"name": "mug", "price": 9, "quantity": 1}]
    # 9 - 50% = 4.5; half-up gives 5, while float round() would give 4.
    assert checkout(items, 50, tax_rate=0) == 5


def test_tax_rate_defaults_to_the_module_default():
    items = [{"name": "mug", "price": 1000, "quantity": 1}]
    assert checkout(items, 0) == checkout(items, 0, tax_rate=DEFAULT_TAX_RATE)


def test_tax_rate_can_vary_per_order():
    items = [{"name": "mug", "price": 1000, "quantity": 1}]
    assert checkout(items, 0, tax_rate=8) == 1080
