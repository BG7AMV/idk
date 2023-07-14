const Discord = require('discord.js');
const ytdl = require('ytdl-core');
const ytdlOptions = { filter: 'audioonly' };
const client = new Discord.Client();
const prefix = '!';

client.on('ready', () => {
  console.log(`Bot ${client.user.tag} olarak giriş yaptı.`);
});

client.on('message', async (message) => {
  if (message.author.bot) return;
  if (!message.content.startsWith(prefix)) return;

  const args = message.content.slice(prefix.length).trim().split(' ');
  const command = args.shift().toLowerCase();

  if (command === 'play') {
    if (!message.member.voice.channel) {
      return message.reply('lütfen bir ses kanalına katılın.');
    }

    const videoName = args.join(' ');
    const voiceChannel = message.member.voice.channel;

    try {
      const connection = await voiceChannel.join();
      const stream = ytdl(videoName, ytdlOptions);
      const dispatcher = connection.play(stream);

      dispatcher.on('start', () => {
        message.channel.send(`**${videoName}** şu anda çalınıyor.`);
      });

      dispatcher.on('finish', () => {
        voiceChannel.leave();
        message.channel.send(`**${videoName}** çalma tamamlandı.`);
      });

      dispatcher.on('error', (error) => {
        console.error(error);
        message.channel.send('Çalma sırasında bir hata oluştu.');
      });
    } catch (error) {
      console.error(error);
      message.channel.send('Ses kanalına katılırken bir hata oluştu.');
    }
  }
});

client.login('BOT_TOKEN');
