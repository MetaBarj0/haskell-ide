FROM alpine:3.12 as base

RUN addgroup -g 1000 hsdev \
    && adduser -u 1000 -G hsdev -h /home/hsdev -D hsdev

RUN apk add --no-cache \
  curl \
  ghc \
  git \
  icu \
  ncurses \
  musl-dev

WORKDIR /home/hsdev

RUN curl -sSL https://get.haskellstack.org/ | sh

USER hsdev

RUN mkdir -p /home/hsdev/.ssh \
    && chmod 0700 /home/hsdev/.ssh

RUN stack upgrade && stack config set system-ghc --global true

FROM base as builder

USER root

RUN apk add --no-cache \
  ncurses-dev \
  zlib-dev

USER hsdev

RUN git clone https://github.com/haskell/haskell-ide-engine.git
WORKDIR /home/hsdev/haskell-ide-engine/install
RUN echo "$(cat shake.yaml | sed -r 's/^(resolver:.*)/# \1/g' | sed -r 's/^# (.*8\.8\.3)$/\1/')" > shake.yaml
WORKDIR /home/hsdev/haskell-ide-engine
RUN stack install.hs
RUN stack install.hs hie-8.8.3
RUN stack install hlint
RUN stack install apply-refact
RUN stack install stylish-haskell

FROM base

USER root

RUN apk add --no-cache \
  screen \
  openssh \
  neovim \
  neovim-doc \
  nodejs \
  yarn

RUN mkdir -p /home/hsdev/.local/bin
RUN chown hsdev:hsdev -R /home/hsdev/.local/bin

COPY --from=builder /home/hsdev/.local/bin/hie /home/hsdev/.local/bin/
COPY --from=builder /home/hsdev/.local/bin/hie-wrapper /home/hsdev/.local/bin/
COPY --from=builder /home/hsdev/.local/bin/hlint /home/hsdev/.local/bin/
COPY --from=builder /home/hsdev/.local/bin/refactor /home/hsdev/.local/bin/
COPY --from=builder /home/hsdev/.local/bin/stylish-haskell /home/hsdev/.local/bin/

RUN chown hsdev:hsdev -R /home/hsdev/

RUN mkdir -p /usr/local/sbin
COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

USER hsdev

RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

RUN mkdir -p .config/nvim/plugged

ENTRYPOINT [ "/usr/local/sbin/entrypoint.sh" ]

LABEL maintainer=MetaBarj0
LABEL role=haskell-ide