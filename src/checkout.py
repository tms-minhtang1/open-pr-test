"""Checkout pipeline."""

from src.cart import apply_discount, subtotal

TAX_RATE = 10


def average_item_price(items):
    """Mean price across the cart."""
    if not items:
        return 0
    return subtotal(items) / len(items)


def checkout(items, coupon_percent, applied_coupons=None):
    """Return the amount to charge, in cents.

    Coupons are applied sequentially, so the discount compounds rather than
    summing (e.g. 10% + 10% yields 19%, not 20%).
    """
    coupons = [*(applied_coupons or []), coupon_percent]

    amount = subtotal(items)
    for percent in coupons:
        amount = apply_discount(amount, percent)

    tax = amount * TAX_RATE / 100
    return round(amount + tax)
