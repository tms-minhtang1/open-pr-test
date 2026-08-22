"""Checkout pipeline."""

from decimal import ROUND_HALF_UP, Decimal

from src.cart import apply_discount, subtotal, to_decimal

DEFAULT_TAX_RATE = 10


def average_item_price(items):
    """Mean price per unit across the cart, in cents."""
    units = sum(item["quantity"] for item in items)
    if not units:
        return Decimal(0)
    return subtotal(items) / units


def checkout(items, coupon_percent, applied_coupons=None, tax_rate=DEFAULT_TAX_RATE):
    """Return the amount to charge, in whole cents.

    Every item ``price`` is already in cents, so this path converts no units.

    Coupons are applied sequentially, so the discount compounds rather than
    summing (e.g. 10% + 10% yields 19%, not 20%).

    ``tax_rate`` is a percentage, defaulting to ``DEFAULT_TAX_RATE``, and a
    negative one raises ValueError rather than reducing the charge below the
    subtotal. The total is rounded half-up, so a half cent always goes to the
    next cent up.
    """
    if tax_rate < 0:
        raise ValueError(f"tax_rate must not be negative, got {tax_rate}")

    coupons = [*(applied_coupons or []), coupon_percent]

    amount = subtotal(items)
    for percent in coupons:
        amount = apply_discount(amount, percent)

    tax = amount * to_decimal(tax_rate) / 100
    return int((amount + tax).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
