import pytest

from src.cart import apply_discount, cart_summary, subtotal


def test_subtotal_weights_by_quantity():
    items = [{"name": "mug", "price": 500, "quantity": 3}]
    assert subtotal(items) == 1500


def test_subtotal_of_empty_cart_is_zero():
    assert subtotal([]) == 0


@pytest.mark.parametrize(
    ("percent", "expected"),
    [(0, 1000), (100, 0)],
)
def test_apply_discount_at_the_bounds(percent, expected):
    assert apply_discount(1000, percent) == expected


@pytest.mark.parametrize("percent", [150, -5])
def test_apply_discount_rejects_out_of_range_percent(percent):
    with pytest.raises(ValueError):
        apply_discount(1000, percent)


def test_cart_summary_line_carries_quantity_and_line_total():
    items = [{"name": "mug", "price": 500, "quantity": 3}]
    assert cart_summary(items) == "mug x3: 15.00 USD"


def test_cart_summary_uses_the_given_currency():
    items = [{"name": "mug", "price": 500, "quantity": 1}]
    assert cart_summary(items, currency="JPY") == "mug x1: 5.00 JPY"
