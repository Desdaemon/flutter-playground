- [Markdown Cheat Sheet](#markdown-cheat-sheet)
  - [Headings](#headings)
- [Heading 1](#heading-1)
  - [Heading 2](#heading-2)
    - [Heading 3](#heading-3)
      - [Heading 4](#heading-4)
        - [Heading 5](#heading-5)
          - [Heading 6](#heading-6)
  - [Paragraphs](#paragraphs)
  - [Formatting](#formatting)
  - [Lists](#lists)
    - [Unordered List](#unordered-list)
    - [Ordered List](#ordered-list)
  - [Tables](#tables)
  - [Blockquotes](#blockquotes)
  - [Code blocks](#code-blocks)
    - [Code spans](#code-spans)
    - [Fenced code blocks](#fenced-code-blocks)
    - [Indented code blocks](#indented-code-blocks)
  - [Comments](#comments)
  - [Links](#links)
    - [Autolinks](#autolinks)
    - [Text Links](#text-links)
    - [Picture Links](#picture-links)
  - [Emojis](#emojis)
- [TeX Cheat Sheet :building_construction:](#tex-cheat-sheet-building_construction)
  - [Inline Math and Math Block](#inline-math-and-math-block)
  - [Accents](#accents)
  - [Delimiters](#delimiters)
    - [Delimiter Sizing](#delimiter-sizing)
  - [Environments](#environments)
- [Appendix](#appendix)
# Markdown Cheat Sheet
## Headings
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

```md
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```
## Paragraphs
This is a sentence in paragraph A.
This is also a sentence in paragraph A.

This is not, however.

```md
This is a sentence in paragraph A.
This is also a sentence in paragraph A.

This is not, however.
```
## Formatting
| Content                | Syntax                   |
| ---------------------- | ------------------------ |
| **Bold**               | `**Bold**`               |
| *Italic*               | `*Italic*`               |
| **Bold then *Italic*** | `**Bold then *Italic***` |
| ~~Removed~~            | `~~Removed~~`            |
## Lists
### Unordered List
- Item 1
- Item 2
- [ ] Item 3 with checkbox
- [x] Item 4 with checked checkbox

```md
- Item 1
- Item 2
- [ ] Item 3 with checkbox
- [x] Item 4 with checked checkbox
```
### Ordered List
1. Une
2. Deux
3. Trois
4. Quatre

```md
1. Une
2. Deux
3. Trois
4. Quatre
```
## Tables
| ID     | Name       | Gender |   Amount |
| ------ | :--------- | :----: | -------: |
| 000001 | Bob Ross   |  Male  |  $123.00 |
| 035002 | Mike Tyson |  Male  |    $5.00 |
| 123456 | Inkling    | Female | $5554.12 |

```md
| ID     | Name       | Gender |   Amount |
| ------ | :--------- | :----: | -------: |
| 000001 | Bob Ross   |  Male  |  $123.00 |
| 035002 | Mike Tyson |  Male  |    $5.00 |
| 123456 | Inkling    | Female | $5554.12 |
```
## Blockquotes
> "Insert wise man quote here" - Anonymous, 2XXX

```md
> "Insert wise man quote here" - Anonymous, 2XXX
```
## Code blocks
### Code spans
`doStuff()` is a method.

```md
`doStuff()` is a method.
```
### Fenced code blocks
```python
if __name__ == "__main__":
    do_stuff()
```
    ```python
    if __name__ == "__main__":
       do_stuff()
    ```
### Indented code blocks
    Indented lines are treated as code blocks.
This is not, however.

```md
    Indented lines are treated as code blocks.
This is not, however.
```
## Comments
```md
<!-- An HTML comment that is invisible in the final output -->
```
## Links
### Autolinks
https://www.google.com

<john@gmail.com>

```md
https://www.google.com

<john@gmail.com>
```
### Text Links
[English Wikipedia](https://en.wikipedia.org)

```md
[English Wikipedia](https://en.wikipedia.org)
```
### Picture Links
[![Link to Penguin](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg/160px-South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg)](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg/160px-South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg)

```md
[![Link to Penguin](...)](...)
```
## Emojis
:smile:
# TeX Cheat Sheet :building_construction:
## Inline Math and Math Block
The result of $1+1$ is $2$.
$$a^2+b^2=c^2$$

```md
The result of $1+1$ is $2$.
$$a^2+b^2=c^2$$
```
## Accents
| Content                    | Syntax                     |
| -------------------------- | -------------------------- |
| $a'$                       | `a'`                       |
| $a''$                      | `a''`                      |
| $a^{\prime}$               | `a^{\prime}`               |
| $\acute{a}$                | `\acute{a}`                |
| $\bar{y}$                  | `\bar{y}`                  |
| $\breve{a}$                | `\breve{a}`                |
| $\check{a}$                | `\check{a}`                |
| $\dot{a}$                  | `\dot{a}`                  |
| $\ddot{a}$                 | `\ddot{a}`                 |
| $\grave{a}$                | `\grave{a}`                |
| $\hat{\theta}$             | `\hat{\theta}`             |
| $\widehat{ac}$             | `\widehat{ac}`             |
| $\tilde{a}$                | `\tilde{a}`                |
| $\widetilde{ac}$           | `\widetilde{ac}`           |
| $\utilde{AB}$              | `\utilde{AB}`              |
| $\vec{F}$                  | `\vec{F}`                  |
| $\overleftarrow{AB}$       | `\overleftarrow{AB}`       |
| $\underleftarrow{AB}$      | `\underleftarrow{AB}`      |
| $\overleftharpoon{ac}$     | `\overleftharpoon{ac}`     |
| $\overleftrightarrow{AB}$  | `\overleftrightarrow{AB}`  |
| $\underleftrightarrow{AB}$ | `\underleftrightarrow{AB}` |
| $\overline{AB}$            | `\overline{AB}`            |
| $\underline{AB}$           | `\underline{AB}`           |
| $\widecheck{ac}$           | `\widecheck{ac}`           |
## Delimiters
| Content                  | Syntax                   |
| ------------------------ | ------------------------ |
| $\lparen\rparen$         | `\lparen\rparen`         |
| $\lbrack\rbrack$         | `\lbrack\rbrack`         |
| $\lbrace\rbrace$         | `\lbrace\rbrace`         |
| $\langle\rangle$         | `\langle\rangle`         |
| $\lang\rang$             | `\lang\rang`             |
| $\vert$                  | `\vert`                  |
| $\lvert\rvert$           | `\lvert\rvert`           |
| $\Vert$                  | `\Vert`                  |
| $\lVert\rVert$           | `\lVert\rVert`           |
| $\lt\gt$                 | `\lt\gt`                 |
| $\lceil\rceil$           | `\lceil\rceil`           |
| $\lfloor\rfloor$         | `\lfloor\rfloor`         |
| $\lmoustache\rmoustache$ | `\lmoustache\rmoustache` |
| $\lgroup\rgroup$         | `\lgroup\rgroup`         |
| $\ulcorner\urcorner$     | `\ulcorner\urcorner`     |
| $\llcorner\lrcorner$     | `\llcorner\lrcorner`     |
| $\llbracket$             | `\llbracket`             |
| $\rrbracket$             | `\rrbracket`             |
| $\uparrow$               | `\uparrow`               |
| $\downarrow$             | `\downarrow`             |
| $\updownarrow$           | `\updownarrow`           |
| $\Uparrow$               | `\Uparrow`               |
| $\Downarrow$             | `\Downarrow`             |
| $\Updownarrow$           | `\Updownarrow`           |
| $\backslash$             | `\backslash`             |
| $\lBrace\rBrace$         | `\lBrace\rBrace`         |
### Delimiter Sizing
$\left(\LARGE{AB}\right)$ `\left(\LARGE{AB}\right)`

$( \big( \Big( \bigg( \Bigg($ `( \big( \Big( \bigg( \Bigg(`

|          |         |          |          |          |
| -------- | ------- | -------- | -------- | -------- |
| `\left`  | `\big`  | `\bigl`  | `\bigm`  | `\bigr`  |
| `\right` | `\Big`  | `\Bigl`  | `\Bigm`  | `\Bigr`  |
| `\right` | `\bigg` | `\biggl` | `\biggm` | `\biggr` |
|          | `\Bigg` | `\Biggl` | `\Biggm` | `\Biggr` |
## Environments
$$
\begin{matrix}
    a&b\\c&d
\end{matrix}
$$
```t
\begin{matrix}
    a & b \\
    c & d
\end{matrix}
```
$$
\begin{pmatrix}
    a&b\\c&d
\end{pmatrix}
$$
```t
\begin{pmatrix}
    a & b \\
    c & d
\end{pmatrix}
```
$$
\begin{Bmatrix}
    a&b\\c&d
\end{Bmatrix}
$$
```t
\begin{Bmatrix}
    a & b \\
    c & d
\end{Bmatrix}
```
$$
x = \begin{cases}
    a &\text{if } b \\
    c &\text{if } d
\end{cases}
$$
```t
x = \begin{cases}
    a &\text{if } b \\
    c &\text{if } d
\end{cases}
```
# Appendix
- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)
- [KaTeX Supported Functions](https://katex.org/docs/supported.html)
- [Flutter Math Demo](https://znjameswu.github.io/flutter_math_demo/#/)