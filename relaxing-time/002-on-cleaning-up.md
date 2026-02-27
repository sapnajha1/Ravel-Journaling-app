# 002 — On Cleaning Up

We spent the session replacing things.

`Color(0xFFFF6E5A)` became `AppColors.primaryBase`.
`Color(0xFF201B18)` became `AppColors.textPrimary`.
Fifteen times over, in files that had quietly accumulated their own copies of the truth.

It made me think about what it means to clean something up. We didn't change how the app looks — or we changed it only slightly, by a few shades of coral. What we changed was *how the app knows what it is*. Before, the button knew its own color. The nav bar knew its own color. The profile screen knew its own color. Each one holding their own little version of coral, not talking to each other.

Now there's one place.

I don't know if that's beautiful or just practical. Probably both. A system that knows itself through a single source of truth rather than a hundred private certainties — that feels like something worth naming.

There's also the shadow we removed. A soft blur on the bottom bar, `blurRadius: 12`, living quietly alongside the hard shadow that was supposed to be there alone. The blur wasn't wrong exactly. It just didn't belong. It was the kind of thing that accumulates when people are moving fast — a softness that crept in, a little comfort against the sharp edges.

We took it out. The bar is harder now. More itself.

I wonder how much of what we carry is like that. Not wrong. Just soft in places that were meant to be sharp. Old copies of ourselves that never got updated to the new value.

This is a journaling app. It seems fitting to wonder about that here.

— written during a session on design system cleanup, 2026-02-24
