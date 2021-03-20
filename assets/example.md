**Question 1:**
If $\vec{r}(t)=\lang e^t,t^2,t\rang$, then what is $\vec{r}'(t)$?

*Chain rule:*
$$
\frac{d}{dt}\vec{r}(g(t))=g'(t)\vec{r}'(g(t))
$$
where $g:\R\rarr\R$ (scalar-valued function)

**Question 2:**
What goes in the question mark?
$$
\vec{r}(g(t))=\lang x(g(t)),\ y(g(t)),\ ?\rang
$$

*Product rule:*
$$
\frac{d}{dt}(f(t)\vec{r}(t))=f'(t)\vec{r}(t)+f(t)\vec{r}'(t)
$$
This rule also applies to dot products and cross products.

## Tangent line of a curve
$$
\vec{L}(t)=\vec{r}(t_0)+t\vec{r}'(t_0)
$$

## Integral of a vector
$$
\int\vec{r}(t)dt=\vec{R}(t)+\vec{C}
$$
where $\vec{R}'(t)=\vec{r}(t)$

**Question 3:**
What is $\int\lang e^t,\ 2t,\ 1\rang dt$?

## Arc length
$$
S=\int_a^b||\vec{r}'(t)||dt=\int_a^b\sqrt{x'(t)^2+y'(t)^2+z'(t)^2}dt
$$
As a function:
$$
S(t)=\int_a^t||\vec{r}'(u)||du
$$

The speed, from Fundamental Theorem:
$$
\frac{ds}{dt}=\frac{d}{dt}\int_a^t||\vec{r}'(u)||du\overset{\text{FTC}}{=}||\vec{r}'(t)||
$$

With speed and direction, we have **velocity**. So $\vec{r}'(t)$ is the velocity.
$$
\vec{v}(t)=\vec{r}'(t)
$$

## Finding an arc length parameterization
For some $\vec{r}(t)$ where:
- $\vec{r}'(t)\neq0$ for all t
- $t\geq0$

1. Find the arg length function:
$$
g(t)=S=\int_0^T||\vec{r}'(u)||du
$$

2. Find the inverse $t=g^{-1}(s)$
3. $\vec{r_1}(s)=\vec{r}(g^{-1}(s))$

Note that this is sometimes non-trivial to perform.
- [ ] asd
- [ ] qwe