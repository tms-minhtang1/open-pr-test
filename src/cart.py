"""Shopping cart totals."""


def subtotal(items):
    """Sum of price * quantity over every item."""
    total = 0
    for item in items:
        total += item["price"] * item["quantity"]
    return total


def apply_discount(amount, percent):
    """Reduce amount by percent."""
    return amount - amount * percent / 100
