---
title: Cubehelix Explained
author: Sander Melnikov <hey@sandydoo.me>
lang: en-GB
toc: true
header-includes:
  - \usepackage{cancel}
    \usepackage{draftwatermark}
    \SetWatermarkLightness{0.95}
---


```{=html}
<h1 style="color: red; text-align: center;">This is a draft.</h1>
```


## Motivation

What is it?
Why do this in the first place?


## Creating a palette

- Describe algorithm.
- Show the helix in 3d space and the resulting palettes.
- Describe plane, using vectors from original paper.
- Show how d3’s implementation is brighter because of the 2x adjustment.


## Do we need the helix?

Alright, so we can generate palettes of colours with monotonically increasing brightness. Our data visualisations now not only look good, but also accurately convey information. But can we do better? I mean, the helix is a fun concept and convenient for generating rainbow palettes, but it lacks precise control over the palette. Want a palette between specifics shade of blue and red? Well, good luck fiddling around with the parameters of the spiral until you get something “close enough”.

Wouldn’t it be nice to be able to interpolate between two specific colours, while maintaining the same perceived intensity? We already know how to adjust our red, green, and blue colour components to adjust for our perception of each component’s intensity. But the original algorithm only allows us to convert locations on a helix to RGB components. Can we somehow convert RGB colours back into this perceptually uniform colour space and make use of it’s beneficial properties?


## Converting RGB values into the cubehelix space

The first people to have had this idea and provide an implementation were Jason Davies and Mike Bostock, as part the d3 visualisation library back in 2015. While the code is open-source LINK, it can be difficult to follow for the uninitiated, and — as far as I know — there is no write up of the mathematics employed in the solution.

```javascript
function cubehelixConvert(o) {
  if (o instanceof Cubehelix) return new Cubehelix(o.h, o.s, o.l, o.opacity);
  if (!(o instanceof Rgb)) o = rgbConvert(o);
  var r = o.r / 255,
      g = o.g / 255,
      b = o.b / 255,
      l = (BC_DA * b + ED * r - EB * g) / (BC_DA + ED - EB),
      bl = b - l,
      k = (E * (g - l) - C * bl) / D,
      s = Math.sqrt(k * k + bl * bl) / (E * l * (1 - l)), // NaN if l=0 or l=1
      h = s ? Math.atan2(k, bl) * degrees - 120 : NaN;
  return new Cubehelix(h < 0 ? h + 360 : h, s, l, o.opacity);
}
```

To really understand what’s going on, we’re going to derive the solution from scratch. We’ll need a tiny bit of linear algebra, and the rest will be some basic geometry and algebra.

- Convert RGB to HSL.


### Lightness

- Lightness — overall brightness of the colours.
- The RGB cube, the diagonal, colourless, overall brightness.
- R, G, and B are three orthogonal vectors. The normal vector to the three is the diagonal.

Cross product of two vectors

\begin{align}
\vec{X} &= Ar + Cg + Eb \\
\vec{Y} &= Br + Dg + Fb \\
l &= \vec{X} \times \vec{Y } \\
l &= \frac{(CF - DE)r + (EB - AF)g + (AD - BC)b}{CF - DE + EB - AF + AD - BC}
\end{align}

Since, in this case, $F = 0$, we can simplify things further.

\begin{align}
l &= \frac{(AD - BC)b - DEr + EBg}{AD - BC - DE + EB}
\end{align}

You might have noticed that the code looks a bit different. Bostock and Davies are computing $\vec{Y} \times \vec{X}$ instead. Why? I’m not sure. But the cross product is anti-commutative, meaning that changing the order of the two vectors in the cross product doesn’t change the result, apart from changing the sign. And since we’re normalising the whole thing, the final lightness will always be positive. So, either way is fine.


### Hue and Saturation

Here’s where things seem a bit confusing at first. At first glance, \texttt{s} and \texttt{h} probably stand for “saturation” and “hue”. But what are \texttt{bl} and \texttt{k}? How do they relate to saturation and hue?

We’ve got several clues. The saturation is computed from the square root of the sum of squares of \texttt{bl} and \texttt{k}. This is the Pythagorean theorem! And the hue — that’s the angle from the positive $x$ axis. So \texttt{bl} and \texttt{k} are the $x$ and $y$ values in a Euclidean plane, respectively. What is this plane though?

- Describe projection.

Let’s recall the original RGB transformation.

\begin{align}
r &= l + \alpha \left( A \cos(h) + B \sin(h) \right) \\
g &= l + \alpha \left( C \cos(h) + D \sin(h) \right) \\
b &= l + \alpha \left( E \cos(h) \right)
\end{align}

where $\alpha = s \cdot l \cdot (1 - l)$.

Remember what the definitions of $\cos(h)$ and $\sin(h)$ are?
Our adjacent and opposite sides are $x$ and $y$, respectively, and the hypotenuse is the saturation $s$.

\begin{align}
\cos(h) &= \frac{x}{s} \\
\sin(h) &= \frac{y}{s}
\end{align}

Let’s plug these values in,

\begin{align}
r &= l + \left( \cancel{s} \cdot l \cdot (1 - l) \right) \cdot \left(A \frac{x}{\cancel{s}} + B \frac{y}{\cancel{s}} \right) \\
g &= l + \left( \cancel{s} \cdot l \cdot (1 - l) \right) \cdot \left(C \frac{x}{\cancel{s}} + D \frac{y}{\cancel{s}} \right) \label{green} \\
b &= l + \left( \cancel{s} \cdot l \cdot (1 - l) \right) \cdot \left(E \frac{x}{\cancel{s}} \right) \label{blue}
\end{align}

We get quite lucky here. Not only do all the $s$ cancel out, meaning we have one less unknown in our set of equations, but, since $F = 0$, we can immediately rearrange equation \eqref{blue} to get $x$.

\begin{align} \label{x}
x &= \frac{b - l}{E \tilde{\alpha}}
\end{align}

where $\tilde{\alpha} = l \cdot ( 1 - l )$.

Now, for the $y$, we replace $x$ with this definition in equation \eqref{green}.

\begin{align}
g &= l + \tilde{\alpha} \cdot \left( \frac{C}{E \tilde{\alpha}}(b - l) + Dy \right) \\
g &= l + \cancel{\tilde{\alpha}} \cdot \left( \frac{C}{\cancel{\tilde{\alpha}} E}(b - l) + Dy \right) \\
g &= l + \frac{C}{E}\left( b - l \right) + \tilde{\alpha} D y \\
y &= \frac{g - l - \frac{C}{E} \left(b - l \right)}{\tilde{\alpha} D} \\
y &= \frac{ \frac{1}{E} \left( E (g - l) - C (b - l) \right) }{ \tilde{\alpha} D } \\
y &= \frac{ E (g - l) - C (b - l) }{ E \tilde{\alpha} D } \label{y}
\end{align}

Fantastic! We’ve got our $x$ and $y$ coordinates. There’s one more clever thing we can do, though. Do you see how in the equations for both $x$ \eqref{x} and $y$ \eqref{y} we’re dividing by $E \tilde{\alpha}$? We can delay that division and work with scaled $x$ and $y$ values, as long as we remember to adjust for it later.

That way we define $\hat{x}$ and $\hat{y}$ as:

\begin{align}
\hat{x} &= E \tilde{\alpha} x = b - l \\
\hat{y} &= E \tilde{\alpha} y = \frac{ E (g - l) - C (b - l) }{ D }
\end{align}

Now our definition for $\hat{x}$ matches \texttt{bl} and $\hat{y}$ matches \texttt{k}.

Saturation in our HSL space is the distance from $(0, 0)$ to $(x, y)$. Using Pythagoras’s theorem,

\begin{align}
s &= \sqrt{ x^2 + y^2 } \\
s &= \sqrt{ \left( \frac{ \hat{x} }{ E \tilde{\alpha} } \right)^2 + \left( \frac{ \hat{y} }{ E \tilde{\alpha} } \right)^2 } \\
s &= \frac{ \sqrt{ \hat{x}^2 + \hat{y}^2 } }{ E \tilde{\alpha} }
\end{align}

Lastly, we can compute the hue using the two-argument inverse tangent function, remembering to convert from radians to degrees,

- EXPLAIN ATAN2

\begin{align}
h &= arctan2 \left( \hat{y}, \hat{x} \right) \cdot \frac{ 180° }{ \pi }
\end{align}


### Spinning the hue

Once last thing! Remember how our $x$ value \eqref{x} was calculated solely from the blue component of our colour? Well, that means that we’ve rotated our coordinate space. Typical hue values are set to $0°$ at red, $120°$ at green, and $240°$ at blue. At $0°$, our hue is actually blue. So we’ve rotated everything by $120°$ counter-clockwise, adding $120°$ to our hue value.

Luckily, there’s a simple fix! We’ll just subtract $120°$ from our final hue, and then, when converting back to RGB, make sure to add it back.

\begin{align}
h &= arctan2 \left( \hat{y}, \hat{x} \right) \cdot \frac{ 180 }{ \pi } - 120°
\end{align}


<!--
## Showing off

EXAMPLES
-->


## Should I use it?

At this point, there’s nothing “cube” or “helix” about this colour space; it’s a cylindrical HSL colour space that can be converted to “adjusted” RGB values. People have created many such “adjusted” colour spaces over the years<!-- EXAMPLES -->, some focused on how humans perceive colours, others correcting for the pecularities of various display technologies. Each has its own set of pros and cons. This colour space tries to adjust the RGB components to create a uniform, even perception of colour intensity — either always increasing, always decreasing, or staying the same across all hues. That’s the pro. The con is that you might create impossible or unrepresentable colours: colours with a saturation or lightness outside of the range that these values can realistically take. In that case, the RGB colour components will be clipped — adjusted to the closest maximum value —, limiting the range of colours you can use while still maintaining perceptual uniformity.

