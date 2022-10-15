FROM ubuntu:22.04@sha256:20fa2d7bb4de7723f542be5923b06c4d704370f0390e4ae9e1c833c8785644c1

ARG DEBIAN_FRONTEND noninteractive

ENV user ctf
ENV prob_port 31337

RUN sed -i "s/archive\.ubuntu\.com/mirror.kakao.com/g" /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y socat=1.7.4.1-3ubuntu4 \
 && rm -rf /var/cache/apt/archives

RUN useradd -m $user

COPY binary_flag/flag /home/$user/flag
COPY binary_flag/prob /home/$user/prob

RUN mkdir /home/$user/drive \
 && chown -R root:$user /home/$user/ \
 && chmod -R 0750 /home/$user/ \
 && chmod 0550 /home/$user/prob \
 && chmod 0440 /home/$user/flag \
 && chmod 0730 /home/$user/drive

EXPOSE $prob_port

CMD socat -T 5 TCP-LISTEN:$prob_port,reuseaddr,fork EXEC:"timeout 60 /home/$user/prob,su=$user,stderr"
