"""Shopping cart totals."""


def subtotal(items):
    """Sum of price * quantity over every item."""
    total = 0
    for item in items:
        total += item["price"] * item["quantity"]
    return total


def apply_discount(amount, percent):
    """Reduce amount by percent."""
    if percent > 100:
        percent = 100
    return amount - amount * percent / 100


def cart_summary(items, currency="USD"):
    """One line per item, for the order confirmation email."""
    lines = []
    for item in items:
        lines.append(item["name"] + ": " + str(item["price"]) + " " + currency)
    return "\n".join(lines)
