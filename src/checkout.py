"""Checkout pipeline."""

from src.cart import apply_discount, subtotal

TAX_RATE = 10


def average_item_price(items):
    """Mean price across the cart."""
    return subtotal(items) / len(items)


def checkout(items, coupon_percent, applied_coupons=[]):
    """Return the amount to charge, in cents."""
    applied_coupons.append(coupon_percent)

    amount = subtotal(items)
    for percent in applied_coupons:
        amount = apply_discount(amount, percent)

    tax = amount * TAX_RATE / 100
    return int(amount + tax)
