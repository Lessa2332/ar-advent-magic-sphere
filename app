// app.js
const startScreen = document.getElementById('start');
const loading = document.getElementById('loading');
const hint = document.getElementById('hint');
const sendBtn = document.getElementById('sendBtn');
let step = 0;
let waitingSound, magicSound;
let elfIdleSprite, elfMagicSprite;

document.getElementById('startBtn').onclick = async () => {
  startScreen.classList.add('hidden');
  loading.classList.remove('hidden');

  const mindar = new MINDAR.ImageThree({
    container: document.body,
    imageTargetSrc: 'targets.mind',
    maxTrack: 2,
    uiLoading: 'no',
    uiScanning: 'no'
  });

  const { scene, camera, renderer } = await mindar.start();
  loading.classList.add('hidden');

  const light = new THREE.HemisphereLight(0xffffff, 0x4444ff, 2);
  scene.add(light);

  const listener = new THREE.AudioListener();
  camera.add(listener);

  // Спрайти ельфа
  const idleTex = new THREE.TextureLoader().load('elf-idle.png');
  idleTex.wrapS = idleTex.wrapT = THREE.RepeatWrapping;
  idleTex.repeat.set(1, 1/24);

  const magicTex = new THREE.TextureLoader().load('elf-magic.png');
  magicTex.wrapS = magicTex.wrapT = THREE.RepeatWrapping;
  magicTex.repeat.set(1, 1/36);

  const idleMaterial = new THREE.SpriteMaterial({ map: idleTex, transparent: true });
  const magicMaterial = new THREE.SpriteMaterial({ map: magicTex, transparent: true });

  elfIdleSprite = new THREE.Sprite(idleMaterial);
  elfIdleSprite.scale.set(0.8, 1.6, 1);
  elfIdleSprite.position.set(1.4, 1.1, -0.8);
  elfIdleSprite.visible = false;

  elfMagicSprite = new THREE.Sprite(magicMaterial);
  elfMagicSprite.scale.set(0.8, 1.6, 1);
  elfMagicSprite.position.copy(elfIdleSprite.position);
  elfMagicSprite.visible = false;

  // Маркер 0 — дзвіночок
  const bellAnchor = mindar.addAnchor(0);
  bellAnchor.onTargetFound = () => {
    if (step === 0) {
      step = 1;
      hint.textContent = "Чудово! Тепер другий слід!";
    }
  };

  // Маркер 1 — зірочка (ельф)
  const starAnchor = mindar.addAnchor(1);
  starAnchor.group.add(elfIdleSprite);
  starAnchor.group.add(elfMagicSprite);

  // Звуки
  const soundPos = new THREE.Object3D();
  soundPos.position.copy(elfIdleSprite.position);
  starAnchor.group.add(soundPos);

  waitingSound = new THREE.PositionalAudio(listener);
  magicSound = new THREE.PositionalAudio(listener);
  soundPos.add(waitingSound);
  soundPos.add(magicSound);

  new THREE.AudioLoader().load('waiting.mp3', buf => { 
    waitingSound.setBuffer(buf); 
    waitingSound.setRefDistance(0.4); 
  });
  new THREE.AudioLoader().load('magic-sound.mp3', buf => { 
    magicSound.setBuffer(buf); 
    magicSound.setRefDistance(0.3); 
  });

  const clock = new THREE.Clock();

  starAnchor.onTargetFound = () => {
    if (step !== 1) return;
    step = 2;
    hint.textContent = "Я десь поруч… підійди ближче, почуєш!";
    waitingSound.setLoop(true);
    waitingSound.play();
    renderer.setAnimationLoop(animate);
  };

  starAnchor.onTargetLost = () => {
    sendBtn.style.display = 'none';
    elfIdleSprite.visible = false;
    if (waitingSound.isPlaying) waitingSound.stop();
  };

  function animate() {
    const delta = clock.getDelta();

    // Відстань до камери
    const worldPos = new THREE.Vector3();
    elfIdleSprite.getWorldPosition(worldPos);
    const dist = camera.position.distanceTo(worldPos);

    // Гучність звуку
    if (waitingSound.isPlaying) {
      const vol = Math.max(0.1, 1 - dist/4);
      waitingSound.setVolume(vol);
    }

    // Показати ельфа коли близько
    const near = dist < 0.7;
    elfIdleSprite.visible = near;
    sendBtn.style.display = near ? 'block' : 'none';

    // Анімація idle (24 кадри, 2.88 сек)
    idleTex.offset.y = (idleTex.offset.y - delta / 2.88) % 1;

    // Анімація магії (якщо запущена)
    if (elfMagicSprite.visible) {
      magicTex.offset.y = (magicTex.offset.y - delta / 2.88) % 1;
    }

    renderer.render(scene, camera);
  }

  sendBtn.onclick = () => {
    step = 3;
    sendBtn.style.display = 'none';
    elfIdleSprite.visible = false;
    waitingSound.stop();

    elfMagicSprite.visible = true;
    magicSound.play();

    hint.innerHTML = "Я передав твоє бажання Санті!<br>Вітаю з Різдвом!";

    setTimeout(() => {
      const restart = document.createElement('button');
      restart.textContent = 'Заново';
      restart.style.marginTop = '30px';
      restart.style.background = '#27ae60';
      restart.onclick = () => location.reload();
      hint.appendChild(restart);
    }, 4000);
  };

};
