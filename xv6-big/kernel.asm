
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 fa 38 10 80       	mov    $0x801038fa,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 a4 85 10 	movl   $0x801085a4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 6c 4f 00 00       	call   80104fba <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 19 4f 00 00       	call   80104fdb <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->blockno == blockno){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 34 4f 00 00       	call   8010503d <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 ed 4b 00 00       	call   80104d11 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 bc 4e 00 00       	call   8010503d <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 ab 85 10 80 	movl   $0x801085ab,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID)) {
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 b6 27 00 00       	call   8010298e <iderw>
  }
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 bc 85 10 80 	movl   $0x801085bc,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 79 27 00 00       	call   8010298e <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 c3 85 10 80 	movl   $0x801085c3,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 9a 4d 00 00       	call   80104fdb <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 48 4b 00 00       	call   80104dea <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 8f 4d 00 00       	call   8010503d <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 dc 03 00 00       	call   8010076b <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 1b 4c 00 00       	call   80104fdb <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 ca 85 10 80 	movl   $0x801085ca,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 75 03 00 00       	call   8010076b <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec d3 85 10 80 	movl   $0x801085d3,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 9f 02 00 00       	call   8010076b <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 83 02 00 00       	call   8010076b <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 75 02 00 00       	call   8010076b <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 6a 02 00 00       	call   8010076b <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 05 4b 00 00       	call   8010503d <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 da 85 10 80 	movl   $0x801085da,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 e9 85 10 80 	movl   $0x801085e9,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 f8 4a 00 00       	call   8010508c <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 eb 85 10 80 	movl   $0x801085eb,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)

  if(pos < 0 || pos > 25*80)
8010068a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010068e:	78 09                	js     80100699 <cgaputc+0xcf>
80100690:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
80100697:	7e 0c                	jle    801006a5 <cgaputc+0xdb>
    panic("pos under/overflow");
80100699:	c7 04 24 ef 85 10 80 	movl   $0x801085ef,(%esp)
801006a0:	e8 95 fe ff ff       	call   8010053a <panic>
  
  if((pos/80) >= 24){  // Scroll up.
801006a5:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801006ac:	7e 53                	jle    80100701 <cgaputc+0x137>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801006ae:	a1 00 90 10 80       	mov    0x80109000,%eax
801006b3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006b9:	a1 00 90 10 80       	mov    0x80109000,%eax
801006be:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006c5:	00 
801006c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801006ca:	89 04 24             	mov    %eax,(%esp)
801006cd:	e8 2c 4c 00 00       	call   801052fe <memmove>
    pos -= 80;
801006d2:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006d6:	b8 80 07 00 00       	mov    $0x780,%eax
801006db:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006de:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006e1:	a1 00 90 10 80       	mov    0x80109000,%eax
801006e6:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006e9:	01 c9                	add    %ecx,%ecx
801006eb:	01 c8                	add    %ecx,%eax
801006ed:	89 54 24 08          	mov    %edx,0x8(%esp)
801006f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006f8:	00 
801006f9:	89 04 24             	mov    %eax,(%esp)
801006fc:	e8 2e 4b 00 00       	call   8010522f <memset>
  }
  
  outb(CRTPORT, 14);
80100701:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
80100708:	00 
80100709:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100710:	e8 b8 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
80100715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100718:	c1 f8 08             	sar    $0x8,%eax
8010071b:	0f b6 c0             	movzbl %al,%eax
8010071e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100722:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100729:	e8 9f fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
8010072e:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100735:	00 
80100736:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010073d:	e8 8b fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100742:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100745:	0f b6 c0             	movzbl %al,%eax
80100748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010074c:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100753:	e8 75 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
80100758:	a1 00 90 10 80       	mov    0x80109000,%eax
8010075d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100760:	01 d2                	add    %edx,%edx
80100762:	01 d0                	add    %edx,%eax
80100764:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
80100769:	c9                   	leave  
8010076a:	c3                   	ret    

8010076b <consputc>:

void
consputc(int c)
{
8010076b:	55                   	push   %ebp
8010076c:	89 e5                	mov    %esp,%ebp
8010076e:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100771:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
80100776:	85 c0                	test   %eax,%eax
80100778:	74 07                	je     80100781 <consputc+0x16>
    cli();
8010077a:	e8 6c fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
8010077f:	eb fe                	jmp    8010077f <consputc+0x14>
  }

  if(c == BACKSPACE){
80100781:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100788:	75 26                	jne    801007b0 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010078a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100791:	e8 50 64 00 00       	call   80106be6 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 44 64 00 00       	call   80106be6 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 38 64 00 00       	call   80106be6 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 2b 64 00 00       	call   80106be6 <uartputc>
  cgaputc(c);
801007bb:	8b 45 08             	mov    0x8(%ebp),%eax
801007be:	89 04 24             	mov    %eax,(%esp)
801007c1:	e8 04 fe ff ff       	call   801005ca <cgaputc>
}
801007c6:	c9                   	leave  
801007c7:	c3                   	ret    

801007c8 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007c8:	55                   	push   %ebp
801007c9:	89 e5                	mov    %esp,%ebp
801007cb:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
801007ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
801007d5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801007dc:	e8 fa 47 00 00       	call   80104fdb <acquire>
  while((c = getc()) >= 0){
801007e1:	e9 39 01 00 00       	jmp    8010091f <consoleintr+0x157>
    switch(c){
801007e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801007e9:	83 f8 10             	cmp    $0x10,%eax
801007ec:	74 1e                	je     8010080c <consoleintr+0x44>
801007ee:	83 f8 10             	cmp    $0x10,%eax
801007f1:	7f 0a                	jg     801007fd <consoleintr+0x35>
801007f3:	83 f8 08             	cmp    $0x8,%eax
801007f6:	74 66                	je     8010085e <consoleintr+0x96>
801007f8:	e9 93 00 00 00       	jmp    80100890 <consoleintr+0xc8>
801007fd:	83 f8 15             	cmp    $0x15,%eax
80100800:	74 31                	je     80100833 <consoleintr+0x6b>
80100802:	83 f8 7f             	cmp    $0x7f,%eax
80100805:	74 57                	je     8010085e <consoleintr+0x96>
80100807:	e9 84 00 00 00       	jmp    80100890 <consoleintr+0xc8>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
8010080c:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100813:	e9 07 01 00 00       	jmp    8010091f <consoleintr+0x157>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100818:	a1 08 08 11 80       	mov    0x80110808,%eax
8010081d:	83 e8 01             	sub    $0x1,%eax
80100820:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(BACKSPACE);
80100825:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010082c:	e8 3a ff ff ff       	call   8010076b <consputc>
80100831:	eb 01                	jmp    80100834 <consoleintr+0x6c>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100833:	90                   	nop
80100834:	8b 15 08 08 11 80    	mov    0x80110808,%edx
8010083a:	a1 04 08 11 80       	mov    0x80110804,%eax
8010083f:	39 c2                	cmp    %eax,%edx
80100841:	74 16                	je     80100859 <consoleintr+0x91>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100843:	a1 08 08 11 80       	mov    0x80110808,%eax
80100848:	83 e8 01             	sub    $0x1,%eax
8010084b:	83 e0 7f             	and    $0x7f,%eax
8010084e:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100855:	3c 0a                	cmp    $0xa,%al
80100857:	75 bf                	jne    80100818 <consoleintr+0x50>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100859:	e9 c1 00 00 00       	jmp    8010091f <consoleintr+0x157>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010085e:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100864:	a1 04 08 11 80       	mov    0x80110804,%eax
80100869:	39 c2                	cmp    %eax,%edx
8010086b:	74 1e                	je     8010088b <consoleintr+0xc3>
        input.e--;
8010086d:	a1 08 08 11 80       	mov    0x80110808,%eax
80100872:	83 e8 01             	sub    $0x1,%eax
80100875:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(BACKSPACE);
8010087a:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100881:	e8 e5 fe ff ff       	call   8010076b <consputc>
      }
      break;
80100886:	e9 94 00 00 00       	jmp    8010091f <consoleintr+0x157>
8010088b:	e9 8f 00 00 00       	jmp    8010091f <consoleintr+0x157>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100890:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100894:	0f 84 84 00 00 00    	je     8010091e <consoleintr+0x156>
8010089a:	8b 15 08 08 11 80    	mov    0x80110808,%edx
801008a0:	a1 00 08 11 80       	mov    0x80110800,%eax
801008a5:	29 c2                	sub    %eax,%edx
801008a7:	89 d0                	mov    %edx,%eax
801008a9:	83 f8 7f             	cmp    $0x7f,%eax
801008ac:	77 70                	ja     8010091e <consoleintr+0x156>
        c = (c == '\r') ? '\n' : c;
801008ae:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801008b2:	74 05                	je     801008b9 <consoleintr+0xf1>
801008b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008b7:	eb 05                	jmp    801008be <consoleintr+0xf6>
801008b9:	b8 0a 00 00 00       	mov    $0xa,%eax
801008be:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008c1:	a1 08 08 11 80       	mov    0x80110808,%eax
801008c6:	8d 50 01             	lea    0x1(%eax),%edx
801008c9:	89 15 08 08 11 80    	mov    %edx,0x80110808
801008cf:	83 e0 7f             	and    $0x7f,%eax
801008d2:	89 c2                	mov    %eax,%edx
801008d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008d7:	88 82 80 07 11 80    	mov    %al,-0x7feef880(%edx)
        consputc(c);
801008dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008e0:	89 04 24             	mov    %eax,(%esp)
801008e3:	e8 83 fe ff ff       	call   8010076b <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008e8:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801008ec:	74 18                	je     80100906 <consoleintr+0x13e>
801008ee:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801008f2:	74 12                	je     80100906 <consoleintr+0x13e>
801008f4:	a1 08 08 11 80       	mov    0x80110808,%eax
801008f9:	8b 15 00 08 11 80    	mov    0x80110800,%edx
801008ff:	83 ea 80             	sub    $0xffffff80,%edx
80100902:	39 d0                	cmp    %edx,%eax
80100904:	75 18                	jne    8010091e <consoleintr+0x156>
          input.w = input.e;
80100906:	a1 08 08 11 80       	mov    0x80110808,%eax
8010090b:	a3 04 08 11 80       	mov    %eax,0x80110804
          wakeup(&input.r);
80100910:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
80100917:	e8 ce 44 00 00       	call   80104dea <wakeup>
        }
      }
      break;
8010091c:	eb 00                	jmp    8010091e <consoleintr+0x156>
8010091e:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
8010091f:	8b 45 08             	mov    0x8(%ebp),%eax
80100922:	ff d0                	call   *%eax
80100924:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100927:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010092b:	0f 89 b5 fe ff ff    	jns    801007e6 <consoleintr+0x1e>
        }
      }
      break;
    }
  }
  release(&cons.lock);
80100931:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100938:	e8 00 47 00 00       	call   8010503d <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 45 45 00 00       	call   80104e8d <procdump>
  }
}
80100948:	c9                   	leave  
80100949:	c3                   	ret    

8010094a <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010094a:	55                   	push   %ebp
8010094b:	89 e5                	mov    %esp,%ebp
8010094d:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100950:	8b 45 08             	mov    0x8(%ebp),%eax
80100953:	89 04 24             	mov    %eax,(%esp)
80100956:	e8 cd 10 00 00       	call   80101a28 <iunlock>
  target = n;
8010095b:	8b 45 10             	mov    0x10(%ebp),%eax
8010095e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100961:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100968:	e8 6e 46 00 00       	call   80104fdb <acquire>
  while(n > 0){
8010096d:	e9 aa 00 00 00       	jmp    80100a1c <consoleread+0xd2>
    while(input.r == input.w){
80100972:	eb 42                	jmp    801009b6 <consoleread+0x6c>
      if(proc->killed){
80100974:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010097a:	8b 40 24             	mov    0x24(%eax),%eax
8010097d:	85 c0                	test   %eax,%eax
8010097f:	74 21                	je     801009a2 <consoleread+0x58>
        release(&cons.lock);
80100981:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100988:	e8 b0 46 00 00       	call   8010503d <release>
        ilock(ip);
8010098d:	8b 45 08             	mov    0x8(%ebp),%eax
80100990:	89 04 24             	mov    %eax,(%esp)
80100993:	e8 3c 0f 00 00       	call   801018d4 <ilock>
        return -1;
80100998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010099d:	e9 a5 00 00 00       	jmp    80100a47 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
801009a2:	c7 44 24 04 c0 b5 10 	movl   $0x8010b5c0,0x4(%esp)
801009a9:	80 
801009aa:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
801009b1:	e8 5b 43 00 00       	call   80104d11 <sleep>

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
801009b6:	8b 15 00 08 11 80    	mov    0x80110800,%edx
801009bc:	a1 04 08 11 80       	mov    0x80110804,%eax
801009c1:	39 c2                	cmp    %eax,%edx
801009c3:	74 af                	je     80100974 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009c5:	a1 00 08 11 80       	mov    0x80110800,%eax
801009ca:	8d 50 01             	lea    0x1(%eax),%edx
801009cd:	89 15 00 08 11 80    	mov    %edx,0x80110800
801009d3:	83 e0 7f             	and    $0x7f,%eax
801009d6:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
801009dd:	0f be c0             	movsbl %al,%eax
801009e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009e3:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009e7:	75 19                	jne    80100a02 <consoleread+0xb8>
      if(n < target){
801009e9:	8b 45 10             	mov    0x10(%ebp),%eax
801009ec:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009ef:	73 0f                	jae    80100a00 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009f1:	a1 00 08 11 80       	mov    0x80110800,%eax
801009f6:	83 e8 01             	sub    $0x1,%eax
801009f9:	a3 00 08 11 80       	mov    %eax,0x80110800
      }
      break;
801009fe:	eb 26                	jmp    80100a26 <consoleread+0xdc>
80100a00:	eb 24                	jmp    80100a26 <consoleread+0xdc>
    }
    *dst++ = c;
80100a02:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a05:	8d 50 01             	lea    0x1(%eax),%edx
80100a08:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a0b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a0e:	88 10                	mov    %dl,(%eax)
    --n;
80100a10:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a14:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a18:	75 02                	jne    80100a1c <consoleread+0xd2>
      break;
80100a1a:	eb 0a                	jmp    80100a26 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100a1c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100a20:	0f 8f 4c ff ff ff    	jg     80100972 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&cons.lock);
80100a26:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a2d:	e8 0b 46 00 00       	call   8010503d <release>
  ilock(ip);
80100a32:	8b 45 08             	mov    0x8(%ebp),%eax
80100a35:	89 04 24             	mov    %eax,(%esp)
80100a38:	e8 97 0e 00 00       	call   801018d4 <ilock>

  return target - n;
80100a3d:	8b 45 10             	mov    0x10(%ebp),%eax
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	29 c2                	sub    %eax,%edx
80100a45:	89 d0                	mov    %edx,%eax
}
80100a47:	c9                   	leave  
80100a48:	c3                   	ret    

80100a49 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a49:	55                   	push   %ebp
80100a4a:	89 e5                	mov    %esp,%ebp
80100a4c:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80100a52:	89 04 24             	mov    %eax,(%esp)
80100a55:	e8 ce 0f 00 00       	call   80101a28 <iunlock>
  acquire(&cons.lock);
80100a5a:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a61:	e8 75 45 00 00       	call   80104fdb <acquire>
  for(i = 0; i < n; i++)
80100a66:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a6d:	eb 1d                	jmp    80100a8c <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a72:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a75:	01 d0                	add    %edx,%eax
80100a77:	0f b6 00             	movzbl (%eax),%eax
80100a7a:	0f be c0             	movsbl %al,%eax
80100a7d:	0f b6 c0             	movzbl %al,%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 e3 fc ff ff       	call   8010076b <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a88:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a8f:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a92:	7c db                	jl     80100a6f <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a94:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a9b:	e8 9d 45 00 00       	call   8010503d <release>
  ilock(ip);
80100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
80100aa3:	89 04 24             	mov    %eax,(%esp)
80100aa6:	e8 29 0e 00 00       	call   801018d4 <ilock>

  return n;
80100aab:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100aae:	c9                   	leave  
80100aaf:	c3                   	ret    

80100ab0 <consoleinit>:

void
consoleinit(void)
{
80100ab0:	55                   	push   %ebp
80100ab1:	89 e5                	mov    %esp,%ebp
80100ab3:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100ab6:	c7 44 24 04 02 86 10 	movl   $0x80108602,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100ac5:	e8 f0 44 00 00       	call   80104fba <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aca:	c7 05 cc 11 11 80 49 	movl   $0x80100a49,0x801111cc
80100ad1:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ad4:	c7 05 c8 11 11 80 4a 	movl   $0x8010094a,0x801111c8
80100adb:	09 10 80 
  cons.locking = 1;
80100ade:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ae5:	00 00 00 

  picenable(IRQ_KBD);
80100ae8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aef:	e8 9e 34 00 00       	call   80103f92 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 42 20 00 00       	call   80102b4a <ioapicenable>
}
80100b08:	c9                   	leave  
80100b09:	c3                   	ret    

80100b0a <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b0a:	55                   	push   %ebp
80100b0b:	89 e5                	mov    %esp,%ebp
80100b0d:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100b13:	e8 db 2a 00 00       	call   801035f3 <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 99 1a 00 00       	call   801025bc <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 46 2b 00 00       	call   80103677 <end_op>
    return -1;
80100b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b36:	e9 e8 03 00 00       	jmp    80100f23 <exec+0x419>
  }
  ilock(ip);
80100b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b3e:	89 04 24             	mov    %eax,(%esp)
80100b41:	e8 8e 0d 00 00       	call   801018d4 <ilock>
  pgdir = 0;
80100b46:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b4d:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b54:	00 
80100b55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b5c:	00 
80100b5d:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b63:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b67:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b6a:	89 04 24             	mov    %eax,(%esp)
80100b6d:	e8 ac 13 00 00       	call   80101f1e <readi>
80100b72:	83 f8 33             	cmp    $0x33,%eax
80100b75:	77 05                	ja     80100b7c <exec+0x72>
    goto bad;
80100b77:	e9 7b 03 00 00       	jmp    80100ef7 <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
80100b7c:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b82:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b87:	74 05                	je     80100b8e <exec+0x84>
    goto bad;
80100b89:	e9 69 03 00 00       	jmp    80100ef7 <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
80100b8e:	e8 a4 71 00 00       	call   80107d37 <setupkvm>
80100b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b96:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b9a:	75 05                	jne    80100ba1 <exec+0x97>
    goto bad;
80100b9c:	e9 56 03 00 00       	jmp    80100ef7 <exec+0x3ed>

  // Load program into memory.
  sz = 0;
80100ba1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100ba8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100baf:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100bb5:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bb8:	e9 cb 00 00 00       	jmp    80100c88 <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bbd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bc0:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bc7:	00 
80100bc8:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bcc:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bd6:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bd9:	89 04 24             	mov    %eax,(%esp)
80100bdc:	e8 3d 13 00 00       	call   80101f1e <readi>
80100be1:	83 f8 20             	cmp    $0x20,%eax
80100be4:	74 05                	je     80100beb <exec+0xe1>
      goto bad;
80100be6:	e9 0c 03 00 00       	jmp    80100ef7 <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
80100beb:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bf1:	83 f8 01             	cmp    $0x1,%eax
80100bf4:	74 05                	je     80100bfb <exec+0xf1>
      continue;
80100bf6:	e9 80 00 00 00       	jmp    80100c7b <exec+0x171>
    if(ph.memsz < ph.filesz)
80100bfb:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100c01:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c07:	39 c2                	cmp    %eax,%edx
80100c09:	73 05                	jae    80100c10 <exec+0x106>
      goto bad;
80100c0b:	e9 e7 02 00 00       	jmp    80100ef7 <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c10:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100c16:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c1c:	01 d0                	add    %edx,%eax
80100c1e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c22:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c25:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c29:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c2c:	89 04 24             	mov    %eax,(%esp)
80100c2f:	e8 d1 74 00 00       	call   80108105 <allocuvm>
80100c34:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c37:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c3b:	75 05                	jne    80100c42 <exec+0x138>
      goto bad;
80100c3d:	e9 b5 02 00 00       	jmp    80100ef7 <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c42:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c48:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c4e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c54:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c58:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c5c:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c5f:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c63:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c67:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c6a:	89 04 24             	mov    %eax,(%esp)
80100c6d:	e8 a8 73 00 00       	call   8010801a <loaduvm>
80100c72:	85 c0                	test   %eax,%eax
80100c74:	79 05                	jns    80100c7b <exec+0x171>
      goto bad;
80100c76:	e9 7c 02 00 00       	jmp    80100ef7 <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c7b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c7f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c82:	83 c0 20             	add    $0x20,%eax
80100c85:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c88:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c8f:	0f b7 c0             	movzwl %ax,%eax
80100c92:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c95:	0f 8f 22 ff ff ff    	jg     80100bbd <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c9b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c9e:	89 04 24             	mov    %eax,(%esp)
80100ca1:	e8 b8 0e 00 00       	call   80101b5e <iunlockput>
  end_op();
80100ca6:	e8 cc 29 00 00       	call   80103677 <end_op>
  ip = 0;
80100cab:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cb2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb5:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cbf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc5:	05 00 20 00 00       	add    $0x2000,%eax
80100cca:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cce:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cd8:	89 04 24             	mov    %eax,(%esp)
80100cdb:	e8 25 74 00 00       	call   80108105 <allocuvm>
80100ce0:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100ce3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ce7:	75 05                	jne    80100cee <exec+0x1e4>
    goto bad;
80100ce9:	e9 09 02 00 00       	jmp    80100ef7 <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cee:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cf1:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cf6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cfa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cfd:	89 04 24             	mov    %eax,(%esp)
80100d00:	e8 30 76 00 00       	call   80108335 <clearpteu>
  sp = sz;
80100d05:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d08:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d0b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d12:	e9 9a 00 00 00       	jmp    80100db1 <exec+0x2a7>
    if(argc >= MAXARG)
80100d17:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d1b:	76 05                	jbe    80100d22 <exec+0x218>
      goto bad;
80100d1d:	e9 d5 01 00 00       	jmp    80100ef7 <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d25:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d2f:	01 d0                	add    %edx,%eax
80100d31:	8b 00                	mov    (%eax),%eax
80100d33:	89 04 24             	mov    %eax,(%esp)
80100d36:	e8 5e 47 00 00       	call   80105499 <strlen>
80100d3b:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d3e:	29 c2                	sub    %eax,%edx
80100d40:	89 d0                	mov    %edx,%eax
80100d42:	83 e8 01             	sub    $0x1,%eax
80100d45:	83 e0 fc             	and    $0xfffffffc,%eax
80100d48:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d4e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d55:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d58:	01 d0                	add    %edx,%eax
80100d5a:	8b 00                	mov    (%eax),%eax
80100d5c:	89 04 24             	mov    %eax,(%esp)
80100d5f:	e8 35 47 00 00       	call   80105499 <strlen>
80100d64:	83 c0 01             	add    $0x1,%eax
80100d67:	89 c2                	mov    %eax,%edx
80100d69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d6c:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d73:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d76:	01 c8                	add    %ecx,%eax
80100d78:	8b 00                	mov    (%eax),%eax
80100d7a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d7e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d82:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d85:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d8c:	89 04 24             	mov    %eax,(%esp)
80100d8f:	e8 66 77 00 00       	call   801084fa <copyout>
80100d94:	85 c0                	test   %eax,%eax
80100d96:	79 05                	jns    80100d9d <exec+0x293>
      goto bad;
80100d98:	e9 5a 01 00 00       	jmp    80100ef7 <exec+0x3ed>
    ustack[3+argc] = sp;
80100d9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da0:	8d 50 03             	lea    0x3(%eax),%edx
80100da3:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100da6:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100dad:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100db1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dbe:	01 d0                	add    %edx,%eax
80100dc0:	8b 00                	mov    (%eax),%eax
80100dc2:	85 c0                	test   %eax,%eax
80100dc4:	0f 85 4d ff ff ff    	jne    80100d17 <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	83 c0 03             	add    $0x3,%eax
80100dd0:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dd7:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100ddb:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100de2:	ff ff ff 
  ustack[1] = argc;
80100de5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de8:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df1:	83 c0 01             	add    $0x1,%eax
80100df4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dfb:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dfe:	29 d0                	sub    %edx,%eax
80100e00:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100e06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e09:	83 c0 04             	add    $0x4,%eax
80100e0c:	c1 e0 02             	shl    $0x2,%eax
80100e0f:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e12:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e15:	83 c0 04             	add    $0x4,%eax
80100e18:	c1 e0 02             	shl    $0x2,%eax
80100e1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e1f:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e25:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e29:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e33:	89 04 24             	mov    %eax,(%esp)
80100e36:	e8 bf 76 00 00       	call   801084fa <copyout>
80100e3b:	85 c0                	test   %eax,%eax
80100e3d:	79 05                	jns    80100e44 <exec+0x33a>
    goto bad;
80100e3f:	e9 b3 00 00 00       	jmp    80100ef7 <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e44:	8b 45 08             	mov    0x8(%ebp),%eax
80100e47:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e50:	eb 17                	jmp    80100e69 <exec+0x35f>
    if(*s == '/')
80100e52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e55:	0f b6 00             	movzbl (%eax),%eax
80100e58:	3c 2f                	cmp    $0x2f,%al
80100e5a:	75 09                	jne    80100e65 <exec+0x35b>
      last = s+1;
80100e5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5f:	83 c0 01             	add    $0x1,%eax
80100e62:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e6c:	0f b6 00             	movzbl (%eax),%eax
80100e6f:	84 c0                	test   %al,%al
80100e71:	75 df                	jne    80100e52 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e79:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e7c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e83:	00 
80100e84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e87:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e8b:	89 14 24             	mov    %edx,(%esp)
80100e8e:	e8 bc 45 00 00       	call   8010544f <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e93:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e99:	8b 40 04             	mov    0x4(%eax),%eax
80100e9c:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100ea8:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100eab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb1:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100eb4:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100eb6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ebc:	8b 40 18             	mov    0x18(%eax),%eax
80100ebf:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100ec5:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ec8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ece:	8b 40 18             	mov    0x18(%eax),%eax
80100ed1:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ed4:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ed7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100edd:	89 04 24             	mov    %eax,(%esp)
80100ee0:	e8 43 6f 00 00       	call   80107e28 <switchuvm>
  freevm(oldpgdir);
80100ee5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ee8:	89 04 24             	mov    %eax,(%esp)
80100eeb:	e8 ab 73 00 00       	call   8010829b <freevm>
  return 0;
80100ef0:	b8 00 00 00 00       	mov    $0x0,%eax
80100ef5:	eb 2c                	jmp    80100f23 <exec+0x419>

 bad:
  if(pgdir)
80100ef7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100efb:	74 0b                	je     80100f08 <exec+0x3fe>
    freevm(pgdir);
80100efd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f00:	89 04 24             	mov    %eax,(%esp)
80100f03:	e8 93 73 00 00       	call   8010829b <freevm>
  if(ip){
80100f08:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f0c:	74 10                	je     80100f1e <exec+0x414>
    iunlockput(ip);
80100f0e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f11:	89 04 24             	mov    %eax,(%esp)
80100f14:	e8 45 0c 00 00       	call   80101b5e <iunlockput>
    end_op();
80100f19:	e8 59 27 00 00       	call   80103677 <end_op>
  }
  return -1;
80100f1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f23:	c9                   	leave  
80100f24:	c3                   	ret    

80100f25 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f25:	55                   	push   %ebp
80100f26:	89 e5                	mov    %esp,%ebp
80100f28:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f2b:	c7 44 24 04 0a 86 10 	movl   $0x8010860a,0x4(%esp)
80100f32:	80 
80100f33:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f3a:	e8 7b 40 00 00       	call   80104fba <initlock>
}
80100f3f:	c9                   	leave  
80100f40:	c3                   	ret    

80100f41 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f41:	55                   	push   %ebp
80100f42:	89 e5                	mov    %esp,%ebp
80100f44:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f47:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f4e:	e8 88 40 00 00       	call   80104fdb <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f53:	c7 45 f4 54 08 11 80 	movl   $0x80110854,-0xc(%ebp)
80100f5a:	eb 29                	jmp    80100f85 <filealloc+0x44>
    if(f->ref == 0){
80100f5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5f:	8b 40 04             	mov    0x4(%eax),%eax
80100f62:	85 c0                	test   %eax,%eax
80100f64:	75 1b                	jne    80100f81 <filealloc+0x40>
      f->ref = 1;
80100f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f69:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f70:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f77:	e8 c1 40 00 00       	call   8010503d <release>
      return f;
80100f7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f7f:	eb 1e                	jmp    80100f9f <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f81:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f85:	81 7d f4 b4 11 11 80 	cmpl   $0x801111b4,-0xc(%ebp)
80100f8c:	72 ce                	jb     80100f5c <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f8e:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100f95:	e8 a3 40 00 00       	call   8010503d <release>
  return 0;
80100f9a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f9f:	c9                   	leave  
80100fa0:	c3                   	ret    

80100fa1 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fa1:	55                   	push   %ebp
80100fa2:	89 e5                	mov    %esp,%ebp
80100fa4:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100fa7:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100fae:	e8 28 40 00 00       	call   80104fdb <acquire>
  if(f->ref < 1)
80100fb3:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb6:	8b 40 04             	mov    0x4(%eax),%eax
80100fb9:	85 c0                	test   %eax,%eax
80100fbb:	7f 0c                	jg     80100fc9 <filedup+0x28>
    panic("filedup");
80100fbd:	c7 04 24 11 86 10 80 	movl   $0x80108611,(%esp)
80100fc4:	e8 71 f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
80100fcc:	8b 40 04             	mov    0x4(%eax),%eax
80100fcf:	8d 50 01             	lea    0x1(%eax),%edx
80100fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd5:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fd8:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100fdf:	e8 59 40 00 00       	call   8010503d <release>
  return f;
80100fe4:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fe7:	c9                   	leave  
80100fe8:	c3                   	ret    

80100fe9 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fe9:	55                   	push   %ebp
80100fea:	89 e5                	mov    %esp,%ebp
80100fec:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fef:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80100ff6:	e8 e0 3f 00 00       	call   80104fdb <acquire>
  if(f->ref < 1)
80100ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80100ffe:	8b 40 04             	mov    0x4(%eax),%eax
80101001:	85 c0                	test   %eax,%eax
80101003:	7f 0c                	jg     80101011 <fileclose+0x28>
    panic("fileclose");
80101005:	c7 04 24 19 86 10 80 	movl   $0x80108619,(%esp)
8010100c:	e8 29 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80101011:	8b 45 08             	mov    0x8(%ebp),%eax
80101014:	8b 40 04             	mov    0x4(%eax),%eax
80101017:	8d 50 ff             	lea    -0x1(%eax),%edx
8010101a:	8b 45 08             	mov    0x8(%ebp),%eax
8010101d:	89 50 04             	mov    %edx,0x4(%eax)
80101020:	8b 45 08             	mov    0x8(%ebp),%eax
80101023:	8b 40 04             	mov    0x4(%eax),%eax
80101026:	85 c0                	test   %eax,%eax
80101028:	7e 11                	jle    8010103b <fileclose+0x52>
    release(&ftable.lock);
8010102a:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
80101031:	e8 07 40 00 00       	call   8010503d <release>
80101036:	e9 82 00 00 00       	jmp    801010bd <fileclose+0xd4>
    return;
  }
  ff = *f;
8010103b:	8b 45 08             	mov    0x8(%ebp),%eax
8010103e:	8b 10                	mov    (%eax),%edx
80101040:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101043:	8b 50 04             	mov    0x4(%eax),%edx
80101046:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101049:	8b 50 08             	mov    0x8(%eax),%edx
8010104c:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010104f:	8b 50 0c             	mov    0xc(%eax),%edx
80101052:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101055:	8b 50 10             	mov    0x10(%eax),%edx
80101058:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010105b:	8b 40 14             	mov    0x14(%eax),%eax
8010105e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101061:	8b 45 08             	mov    0x8(%ebp),%eax
80101064:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010106b:	8b 45 08             	mov    0x8(%ebp),%eax
8010106e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101074:	c7 04 24 20 08 11 80 	movl   $0x80110820,(%esp)
8010107b:	e8 bd 3f 00 00       	call   8010503d <release>
  
  if(ff.type == FD_PIPE)
80101080:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101083:	83 f8 01             	cmp    $0x1,%eax
80101086:	75 18                	jne    801010a0 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101088:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010108c:	0f be d0             	movsbl %al,%edx
8010108f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101092:	89 54 24 04          	mov    %edx,0x4(%esp)
80101096:	89 04 24             	mov    %eax,(%esp)
80101099:	e8 a4 31 00 00       	call   80104242 <pipeclose>
8010109e:	eb 1d                	jmp    801010bd <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010a3:	83 f8 02             	cmp    $0x2,%eax
801010a6:	75 15                	jne    801010bd <fileclose+0xd4>
    begin_op();
801010a8:	e8 46 25 00 00       	call   801035f3 <begin_op>
    iput(ff.ip);
801010ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010b0:	89 04 24             	mov    %eax,(%esp)
801010b3:	e8 d5 09 00 00       	call   80101a8d <iput>
    end_op();
801010b8:	e8 ba 25 00 00       	call   80103677 <end_op>
  }
}
801010bd:	c9                   	leave  
801010be:	c3                   	ret    

801010bf <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010bf:	55                   	push   %ebp
801010c0:	89 e5                	mov    %esp,%ebp
801010c2:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010c5:	8b 45 08             	mov    0x8(%ebp),%eax
801010c8:	8b 00                	mov    (%eax),%eax
801010ca:	83 f8 02             	cmp    $0x2,%eax
801010cd:	75 38                	jne    80101107 <filestat+0x48>
    ilock(f->ip);
801010cf:	8b 45 08             	mov    0x8(%ebp),%eax
801010d2:	8b 40 10             	mov    0x10(%eax),%eax
801010d5:	89 04 24             	mov    %eax,(%esp)
801010d8:	e8 f7 07 00 00       	call   801018d4 <ilock>
    stati(f->ip, st);
801010dd:	8b 45 08             	mov    0x8(%ebp),%eax
801010e0:	8b 40 10             	mov    0x10(%eax),%eax
801010e3:	8b 55 0c             	mov    0xc(%ebp),%edx
801010e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801010ea:	89 04 24             	mov    %eax,(%esp)
801010ed:	e8 e7 0d 00 00       	call   80101ed9 <stati>
    iunlock(f->ip);
801010f2:	8b 45 08             	mov    0x8(%ebp),%eax
801010f5:	8b 40 10             	mov    0x10(%eax),%eax
801010f8:	89 04 24             	mov    %eax,(%esp)
801010fb:	e8 28 09 00 00       	call   80101a28 <iunlock>
    return 0;
80101100:	b8 00 00 00 00       	mov    $0x0,%eax
80101105:	eb 05                	jmp    8010110c <filestat+0x4d>
  }
  return -1;
80101107:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010110c:	c9                   	leave  
8010110d:	c3                   	ret    

8010110e <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
8010110e:	55                   	push   %ebp
8010110f:	89 e5                	mov    %esp,%ebp
80101111:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101114:	8b 45 08             	mov    0x8(%ebp),%eax
80101117:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010111b:	84 c0                	test   %al,%al
8010111d:	75 0a                	jne    80101129 <fileread+0x1b>
    return -1;
8010111f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101124:	e9 9f 00 00 00       	jmp    801011c8 <fileread+0xba>
  if(f->type == FD_PIPE)
80101129:	8b 45 08             	mov    0x8(%ebp),%eax
8010112c:	8b 00                	mov    (%eax),%eax
8010112e:	83 f8 01             	cmp    $0x1,%eax
80101131:	75 1e                	jne    80101151 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101133:	8b 45 08             	mov    0x8(%ebp),%eax
80101136:	8b 40 0c             	mov    0xc(%eax),%eax
80101139:	8b 55 10             	mov    0x10(%ebp),%edx
8010113c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101140:	8b 55 0c             	mov    0xc(%ebp),%edx
80101143:	89 54 24 04          	mov    %edx,0x4(%esp)
80101147:	89 04 24             	mov    %eax,(%esp)
8010114a:	e8 74 32 00 00       	call   801043c3 <piperead>
8010114f:	eb 77                	jmp    801011c8 <fileread+0xba>
  if(f->type == FD_INODE){
80101151:	8b 45 08             	mov    0x8(%ebp),%eax
80101154:	8b 00                	mov    (%eax),%eax
80101156:	83 f8 02             	cmp    $0x2,%eax
80101159:	75 61                	jne    801011bc <fileread+0xae>
    ilock(f->ip);
8010115b:	8b 45 08             	mov    0x8(%ebp),%eax
8010115e:	8b 40 10             	mov    0x10(%eax),%eax
80101161:	89 04 24             	mov    %eax,(%esp)
80101164:	e8 6b 07 00 00       	call   801018d4 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101169:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010116c:	8b 45 08             	mov    0x8(%ebp),%eax
8010116f:	8b 50 14             	mov    0x14(%eax),%edx
80101172:	8b 45 08             	mov    0x8(%ebp),%eax
80101175:	8b 40 10             	mov    0x10(%eax),%eax
80101178:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010117c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101180:	8b 55 0c             	mov    0xc(%ebp),%edx
80101183:	89 54 24 04          	mov    %edx,0x4(%esp)
80101187:	89 04 24             	mov    %eax,(%esp)
8010118a:	e8 8f 0d 00 00       	call   80101f1e <readi>
8010118f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101192:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101196:	7e 11                	jle    801011a9 <fileread+0x9b>
      f->off += r;
80101198:	8b 45 08             	mov    0x8(%ebp),%eax
8010119b:	8b 50 14             	mov    0x14(%eax),%edx
8010119e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011a1:	01 c2                	add    %eax,%edx
801011a3:	8b 45 08             	mov    0x8(%ebp),%eax
801011a6:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011a9:	8b 45 08             	mov    0x8(%ebp),%eax
801011ac:	8b 40 10             	mov    0x10(%eax),%eax
801011af:	89 04 24             	mov    %eax,(%esp)
801011b2:	e8 71 08 00 00       	call   80101a28 <iunlock>
    return r;
801011b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011ba:	eb 0c                	jmp    801011c8 <fileread+0xba>
  }
  panic("fileread");
801011bc:	c7 04 24 23 86 10 80 	movl   $0x80108623,(%esp)
801011c3:	e8 72 f3 ff ff       	call   8010053a <panic>
}
801011c8:	c9                   	leave  
801011c9:	c3                   	ret    

801011ca <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011ca:	55                   	push   %ebp
801011cb:	89 e5                	mov    %esp,%ebp
801011cd:	53                   	push   %ebx
801011ce:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011d1:	8b 45 08             	mov    0x8(%ebp),%eax
801011d4:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011d8:	84 c0                	test   %al,%al
801011da:	75 0a                	jne    801011e6 <filewrite+0x1c>
    return -1;
801011dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011e1:	e9 20 01 00 00       	jmp    80101306 <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011e6:	8b 45 08             	mov    0x8(%ebp),%eax
801011e9:	8b 00                	mov    (%eax),%eax
801011eb:	83 f8 01             	cmp    $0x1,%eax
801011ee:	75 21                	jne    80101211 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011f0:	8b 45 08             	mov    0x8(%ebp),%eax
801011f3:	8b 40 0c             	mov    0xc(%eax),%eax
801011f6:	8b 55 10             	mov    0x10(%ebp),%edx
801011f9:	89 54 24 08          	mov    %edx,0x8(%esp)
801011fd:	8b 55 0c             	mov    0xc(%ebp),%edx
80101200:	89 54 24 04          	mov    %edx,0x4(%esp)
80101204:	89 04 24             	mov    %eax,(%esp)
80101207:	e8 c8 30 00 00       	call   801042d4 <pipewrite>
8010120c:	e9 f5 00 00 00       	jmp    80101306 <filewrite+0x13c>
  if(f->type == FD_INODE){
80101211:	8b 45 08             	mov    0x8(%ebp),%eax
80101214:	8b 00                	mov    (%eax),%eax
80101216:	83 f8 02             	cmp    $0x2,%eax
80101219:	0f 85 db 00 00 00    	jne    801012fa <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
8010121f:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101226:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
8010122d:	e9 a8 00 00 00       	jmp    801012da <filewrite+0x110>
      int n1 = n - i;
80101232:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101235:	8b 55 10             	mov    0x10(%ebp),%edx
80101238:	29 c2                	sub    %eax,%edx
8010123a:	89 d0                	mov    %edx,%eax
8010123c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
8010123f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101242:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101245:	7e 06                	jle    8010124d <filewrite+0x83>
        n1 = max;
80101247:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010124a:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
8010124d:	e8 a1 23 00 00       	call   801035f3 <begin_op>
      ilock(f->ip);
80101252:	8b 45 08             	mov    0x8(%ebp),%eax
80101255:	8b 40 10             	mov    0x10(%eax),%eax
80101258:	89 04 24             	mov    %eax,(%esp)
8010125b:	e8 74 06 00 00       	call   801018d4 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101260:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101263:	8b 45 08             	mov    0x8(%ebp),%eax
80101266:	8b 50 14             	mov    0x14(%eax),%edx
80101269:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010126c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010126f:	01 c3                	add    %eax,%ebx
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 40 10             	mov    0x10(%eax),%eax
80101277:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010127b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010127f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101283:	89 04 24             	mov    %eax,(%esp)
80101286:	e8 f7 0d 00 00       	call   80102082 <writei>
8010128b:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010128e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101292:	7e 11                	jle    801012a5 <filewrite+0xdb>
        f->off += r;
80101294:	8b 45 08             	mov    0x8(%ebp),%eax
80101297:	8b 50 14             	mov    0x14(%eax),%edx
8010129a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129d:	01 c2                	add    %eax,%edx
8010129f:	8b 45 08             	mov    0x8(%ebp),%eax
801012a2:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012a5:	8b 45 08             	mov    0x8(%ebp),%eax
801012a8:	8b 40 10             	mov    0x10(%eax),%eax
801012ab:	89 04 24             	mov    %eax,(%esp)
801012ae:	e8 75 07 00 00       	call   80101a28 <iunlock>
      end_op();
801012b3:	e8 bf 23 00 00       	call   80103677 <end_op>

      if(r < 0)
801012b8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012bc:	79 02                	jns    801012c0 <filewrite+0xf6>
        break;
801012be:	eb 26                	jmp    801012e6 <filewrite+0x11c>
      if(r != n1)
801012c0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012c3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012c6:	74 0c                	je     801012d4 <filewrite+0x10a>
        panic("short filewrite");
801012c8:	c7 04 24 2c 86 10 80 	movl   $0x8010862c,(%esp)
801012cf:	e8 66 f2 ff ff       	call   8010053a <panic>
      i += r;
801012d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012d7:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012dd:	3b 45 10             	cmp    0x10(%ebp),%eax
801012e0:	0f 8c 4c ff ff ff    	jl     80101232 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012e9:	3b 45 10             	cmp    0x10(%ebp),%eax
801012ec:	75 05                	jne    801012f3 <filewrite+0x129>
801012ee:	8b 45 10             	mov    0x10(%ebp),%eax
801012f1:	eb 05                	jmp    801012f8 <filewrite+0x12e>
801012f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012f8:	eb 0c                	jmp    80101306 <filewrite+0x13c>
  }
  panic("filewrite");
801012fa:	c7 04 24 3c 86 10 80 	movl   $0x8010863c,(%esp)
80101301:	e8 34 f2 ff ff       	call   8010053a <panic>
}
80101306:	83 c4 24             	add    $0x24,%esp
80101309:	5b                   	pop    %ebx
8010130a:	5d                   	pop    %ebp
8010130b:	c3                   	ret    

8010130c <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
8010130c:	55                   	push   %ebp
8010130d:	89 e5                	mov    %esp,%ebp
8010130f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101312:	8b 45 08             	mov    0x8(%ebp),%eax
80101315:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010131c:	00 
8010131d:	89 04 24             	mov    %eax,(%esp)
80101320:	e8 81 ee ff ff       	call   801001a6 <bread>
80101325:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101328:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010132b:	83 c0 18             	add    $0x18,%eax
8010132e:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
80101335:	00 
80101336:	89 44 24 04          	mov    %eax,0x4(%esp)
8010133a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 b9 3f 00 00       	call   801052fe <memmove>
  brelse(bp);
80101345:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101348:	89 04 24             	mov    %eax,(%esp)
8010134b:	e8 c7 ee ff ff       	call   80100217 <brelse>
}
80101350:	c9                   	leave  
80101351:	c3                   	ret    

80101352 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101352:	55                   	push   %ebp
80101353:	89 e5                	mov    %esp,%ebp
80101355:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101358:	8b 55 0c             	mov    0xc(%ebp),%edx
8010135b:	8b 45 08             	mov    0x8(%ebp),%eax
8010135e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101362:	89 04 24             	mov    %eax,(%esp)
80101365:	e8 3c ee ff ff       	call   801001a6 <bread>
8010136a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010136d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101370:	83 c0 18             	add    $0x18,%eax
80101373:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010137a:	00 
8010137b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101382:	00 
80101383:	89 04 24             	mov    %eax,(%esp)
80101386:	e8 a4 3e 00 00       	call   8010522f <memset>
  log_write(bp);
8010138b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010138e:	89 04 24             	mov    %eax,(%esp)
80101391:	e8 68 24 00 00       	call   801037fe <log_write>
  brelse(bp);
80101396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101399:	89 04 24             	mov    %eax,(%esp)
8010139c:	e8 76 ee ff ff       	call   80100217 <brelse>
}
801013a1:	c9                   	leave  
801013a2:	c3                   	ret    

801013a3 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013a3:	55                   	push   %ebp
801013a4:	89 e5                	mov    %esp,%ebp
801013a6:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801013a9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801013b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013b7:	e9 07 01 00 00       	jmp    801014c3 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
801013bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013bf:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013c5:	85 c0                	test   %eax,%eax
801013c7:	0f 48 c2             	cmovs  %edx,%eax
801013ca:	c1 f8 0c             	sar    $0xc,%eax
801013cd:	89 c2                	mov    %eax,%edx
801013cf:	a1 38 12 11 80       	mov    0x80111238,%eax
801013d4:	01 d0                	add    %edx,%eax
801013d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801013da:	8b 45 08             	mov    0x8(%ebp),%eax
801013dd:	89 04 24             	mov    %eax,(%esp)
801013e0:	e8 c1 ed ff ff       	call   801001a6 <bread>
801013e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013e8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013ef:	e9 9d 00 00 00       	jmp    80101491 <balloc+0xee>
      m = 1 << (bi % 8);
801013f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013f7:	99                   	cltd   
801013f8:	c1 ea 1d             	shr    $0x1d,%edx
801013fb:	01 d0                	add    %edx,%eax
801013fd:	83 e0 07             	and    $0x7,%eax
80101400:	29 d0                	sub    %edx,%eax
80101402:	ba 01 00 00 00       	mov    $0x1,%edx
80101407:	89 c1                	mov    %eax,%ecx
80101409:	d3 e2                	shl    %cl,%edx
8010140b:	89 d0                	mov    %edx,%eax
8010140d:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101410:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101413:	8d 50 07             	lea    0x7(%eax),%edx
80101416:	85 c0                	test   %eax,%eax
80101418:	0f 48 c2             	cmovs  %edx,%eax
8010141b:	c1 f8 03             	sar    $0x3,%eax
8010141e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101421:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101426:	0f b6 c0             	movzbl %al,%eax
80101429:	23 45 e8             	and    -0x18(%ebp),%eax
8010142c:	85 c0                	test   %eax,%eax
8010142e:	75 5d                	jne    8010148d <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101430:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101433:	8d 50 07             	lea    0x7(%eax),%edx
80101436:	85 c0                	test   %eax,%eax
80101438:	0f 48 c2             	cmovs  %edx,%eax
8010143b:	c1 f8 03             	sar    $0x3,%eax
8010143e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101441:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101446:	89 d1                	mov    %edx,%ecx
80101448:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010144b:	09 ca                	or     %ecx,%edx
8010144d:	89 d1                	mov    %edx,%ecx
8010144f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101452:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101456:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101459:	89 04 24             	mov    %eax,(%esp)
8010145c:	e8 9d 23 00 00       	call   801037fe <log_write>
        brelse(bp);
80101461:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101464:	89 04 24             	mov    %eax,(%esp)
80101467:	e8 ab ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010146c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010146f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101472:	01 c2                	add    %eax,%edx
80101474:	8b 45 08             	mov    0x8(%ebp),%eax
80101477:	89 54 24 04          	mov    %edx,0x4(%esp)
8010147b:	89 04 24             	mov    %eax,(%esp)
8010147e:	e8 cf fe ff ff       	call   80101352 <bzero>
        return b + bi;
80101483:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101486:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101489:	01 d0                	add    %edx,%eax
8010148b:	eb 52                	jmp    801014df <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010148d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101491:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101498:	7f 17                	jg     801014b1 <balloc+0x10e>
8010149a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010149d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014a0:	01 d0                	add    %edx,%eax
801014a2:	89 c2                	mov    %eax,%edx
801014a4:	a1 20 12 11 80       	mov    0x80111220,%eax
801014a9:	39 c2                	cmp    %eax,%edx
801014ab:	0f 82 43 ff ff ff    	jb     801013f4 <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014b4:	89 04 24             	mov    %eax,(%esp)
801014b7:	e8 5b ed ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
801014bc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c6:	a1 20 12 11 80       	mov    0x80111220,%eax
801014cb:	39 c2                	cmp    %eax,%edx
801014cd:	0f 82 e9 fe ff ff    	jb     801013bc <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014d3:	c7 04 24 48 86 10 80 	movl   $0x80108648,(%esp)
801014da:	e8 5b f0 ff ff       	call   8010053a <panic>
}
801014df:	c9                   	leave  
801014e0:	c3                   	ret    

801014e1 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014e1:	55                   	push   %ebp
801014e2:	89 e5                	mov    %esp,%ebp
801014e4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
801014e7:	c7 44 24 04 20 12 11 	movl   $0x80111220,0x4(%esp)
801014ee:	80 
801014ef:	8b 45 08             	mov    0x8(%ebp),%eax
801014f2:	89 04 24             	mov    %eax,(%esp)
801014f5:	e8 12 fe ff ff       	call   8010130c <readsb>
  bp = bread(dev, BBLOCK(b, sb));
801014fa:	8b 45 0c             	mov    0xc(%ebp),%eax
801014fd:	c1 e8 0c             	shr    $0xc,%eax
80101500:	89 c2                	mov    %eax,%edx
80101502:	a1 38 12 11 80       	mov    0x80111238,%eax
80101507:	01 c2                	add    %eax,%edx
80101509:	8b 45 08             	mov    0x8(%ebp),%eax
8010150c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101510:	89 04 24             	mov    %eax,(%esp)
80101513:	e8 8e ec ff ff       	call   801001a6 <bread>
80101518:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010151b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010151e:	25 ff 0f 00 00       	and    $0xfff,%eax
80101523:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101526:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101529:	99                   	cltd   
8010152a:	c1 ea 1d             	shr    $0x1d,%edx
8010152d:	01 d0                	add    %edx,%eax
8010152f:	83 e0 07             	and    $0x7,%eax
80101532:	29 d0                	sub    %edx,%eax
80101534:	ba 01 00 00 00       	mov    $0x1,%edx
80101539:	89 c1                	mov    %eax,%ecx
8010153b:	d3 e2                	shl    %cl,%edx
8010153d:	89 d0                	mov    %edx,%eax
8010153f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101542:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101545:	8d 50 07             	lea    0x7(%eax),%edx
80101548:	85 c0                	test   %eax,%eax
8010154a:	0f 48 c2             	cmovs  %edx,%eax
8010154d:	c1 f8 03             	sar    $0x3,%eax
80101550:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101553:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101558:	0f b6 c0             	movzbl %al,%eax
8010155b:	23 45 ec             	and    -0x14(%ebp),%eax
8010155e:	85 c0                	test   %eax,%eax
80101560:	75 0c                	jne    8010156e <bfree+0x8d>
    panic("freeing free block");
80101562:	c7 04 24 5e 86 10 80 	movl   $0x8010865e,(%esp)
80101569:	e8 cc ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
8010156e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101571:	8d 50 07             	lea    0x7(%eax),%edx
80101574:	85 c0                	test   %eax,%eax
80101576:	0f 48 c2             	cmovs  %edx,%eax
80101579:	c1 f8 03             	sar    $0x3,%eax
8010157c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157f:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101584:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101587:	f7 d1                	not    %ecx
80101589:	21 ca                	and    %ecx,%edx
8010158b:	89 d1                	mov    %edx,%ecx
8010158d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101590:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101597:	89 04 24             	mov    %eax,(%esp)
8010159a:	e8 5f 22 00 00       	call   801037fe <log_write>
  brelse(bp);
8010159f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015a2:	89 04 24             	mov    %eax,(%esp)
801015a5:	e8 6d ec ff ff       	call   80100217 <brelse>
}
801015aa:	c9                   	leave  
801015ab:	c3                   	ret    

801015ac <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
801015ac:	55                   	push   %ebp
801015ad:	89 e5                	mov    %esp,%ebp
801015af:	57                   	push   %edi
801015b0:	56                   	push   %esi
801015b1:	53                   	push   %ebx
801015b2:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
801015b5:	c7 44 24 04 71 86 10 	movl   $0x80108671,0x4(%esp)
801015bc:	80 
801015bd:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801015c4:	e8 f1 39 00 00       	call   80104fba <initlock>
  readsb(dev, &sb);
801015c9:	c7 44 24 04 20 12 11 	movl   $0x80111220,0x4(%esp)
801015d0:	80 
801015d1:	8b 45 08             	mov    0x8(%ebp),%eax
801015d4:	89 04 24             	mov    %eax,(%esp)
801015d7:	e8 30 fd ff ff       	call   8010130c <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
801015dc:	a1 38 12 11 80       	mov    0x80111238,%eax
801015e1:	8b 3d 34 12 11 80    	mov    0x80111234,%edi
801015e7:	8b 35 30 12 11 80    	mov    0x80111230,%esi
801015ed:	8b 1d 2c 12 11 80    	mov    0x8011122c,%ebx
801015f3:	8b 0d 28 12 11 80    	mov    0x80111228,%ecx
801015f9:	8b 15 24 12 11 80    	mov    0x80111224,%edx
801015ff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101602:	8b 15 20 12 11 80    	mov    0x80111220,%edx
80101608:	89 44 24 1c          	mov    %eax,0x1c(%esp)
8010160c:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101610:	89 74 24 14          	mov    %esi,0x14(%esp)
80101614:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80101618:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010161c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010161f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101623:	89 d0                	mov    %edx,%eax
80101625:	89 44 24 04          	mov    %eax,0x4(%esp)
80101629:	c7 04 24 78 86 10 80 	movl   $0x80108678,(%esp)
80101630:	e8 6b ed ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
80101635:	83 c4 3c             	add    $0x3c,%esp
80101638:	5b                   	pop    %ebx
80101639:	5e                   	pop    %esi
8010163a:	5f                   	pop    %edi
8010163b:	5d                   	pop    %ebp
8010163c:	c3                   	ret    

8010163d <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010163d:	55                   	push   %ebp
8010163e:	89 e5                	mov    %esp,%ebp
80101640:	83 ec 28             	sub    $0x28,%esp
80101643:	8b 45 0c             	mov    0xc(%ebp),%eax
80101646:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010164a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101651:	e9 9e 00 00 00       	jmp    801016f4 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101659:	c1 e8 03             	shr    $0x3,%eax
8010165c:	89 c2                	mov    %eax,%edx
8010165e:	a1 34 12 11 80       	mov    0x80111234,%eax
80101663:	01 d0                	add    %edx,%eax
80101665:	89 44 24 04          	mov    %eax,0x4(%esp)
80101669:	8b 45 08             	mov    0x8(%ebp),%eax
8010166c:	89 04 24             	mov    %eax,(%esp)
8010166f:	e8 32 eb ff ff       	call   801001a6 <bread>
80101674:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167a:	8d 50 18             	lea    0x18(%eax),%edx
8010167d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101680:	83 e0 07             	and    $0x7,%eax
80101683:	c1 e0 06             	shl    $0x6,%eax
80101686:	01 d0                	add    %edx,%eax
80101688:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010168b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010168e:	0f b7 00             	movzwl (%eax),%eax
80101691:	66 85 c0             	test   %ax,%ax
80101694:	75 4f                	jne    801016e5 <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
80101696:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010169d:	00 
8010169e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801016a5:	00 
801016a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016a9:	89 04 24             	mov    %eax,(%esp)
801016ac:	e8 7e 3b 00 00       	call   8010522f <memset>
      dip->type = type;
801016b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016b4:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801016b8:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801016bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016be:	89 04 24             	mov    %eax,(%esp)
801016c1:	e8 38 21 00 00       	call   801037fe <log_write>
      brelse(bp);
801016c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016c9:	89 04 24             	mov    %eax,(%esp)
801016cc:	e8 46 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801016d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801016d8:	8b 45 08             	mov    0x8(%ebp),%eax
801016db:	89 04 24             	mov    %eax,(%esp)
801016de:	e8 ed 00 00 00       	call   801017d0 <iget>
801016e3:	eb 2b                	jmp    80101710 <ialloc+0xd3>
    }
    brelse(bp);
801016e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016e8:	89 04 24             	mov    %eax,(%esp)
801016eb:	e8 27 eb ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
801016f0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016f7:	a1 28 12 11 80       	mov    0x80111228,%eax
801016fc:	39 c2                	cmp    %eax,%edx
801016fe:	0f 82 52 ff ff ff    	jb     80101656 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101704:	c7 04 24 cb 86 10 80 	movl   $0x801086cb,(%esp)
8010170b:	e8 2a ee ff ff       	call   8010053a <panic>
}
80101710:	c9                   	leave  
80101711:	c3                   	ret    

80101712 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101712:	55                   	push   %ebp
80101713:	89 e5                	mov    %esp,%ebp
80101715:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101718:	8b 45 08             	mov    0x8(%ebp),%eax
8010171b:	8b 40 04             	mov    0x4(%eax),%eax
8010171e:	c1 e8 03             	shr    $0x3,%eax
80101721:	89 c2                	mov    %eax,%edx
80101723:	a1 34 12 11 80       	mov    0x80111234,%eax
80101728:	01 c2                	add    %eax,%edx
8010172a:	8b 45 08             	mov    0x8(%ebp),%eax
8010172d:	8b 00                	mov    (%eax),%eax
8010172f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101733:	89 04 24             	mov    %eax,(%esp)
80101736:	e8 6b ea ff ff       	call   801001a6 <bread>
8010173b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010173e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101741:	8d 50 18             	lea    0x18(%eax),%edx
80101744:	8b 45 08             	mov    0x8(%ebp),%eax
80101747:	8b 40 04             	mov    0x4(%eax),%eax
8010174a:	83 e0 07             	and    $0x7,%eax
8010174d:	c1 e0 06             	shl    $0x6,%eax
80101750:	01 d0                	add    %edx,%eax
80101752:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101755:	8b 45 08             	mov    0x8(%ebp),%eax
80101758:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010175c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010175f:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101762:	8b 45 08             	mov    0x8(%ebp),%eax
80101765:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101769:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010176c:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101770:	8b 45 08             	mov    0x8(%ebp),%eax
80101773:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101777:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010177a:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010177e:	8b 45 08             	mov    0x8(%ebp),%eax
80101781:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101785:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101788:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010178c:	8b 45 08             	mov    0x8(%ebp),%eax
8010178f:	8b 50 18             	mov    0x18(%eax),%edx
80101792:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101795:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101798:	8b 45 08             	mov    0x8(%ebp),%eax
8010179b:	8d 50 1c             	lea    0x1c(%eax),%edx
8010179e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a1:	83 c0 0c             	add    $0xc,%eax
801017a4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801017ab:	00 
801017ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801017b0:	89 04 24             	mov    %eax,(%esp)
801017b3:	e8 46 3b 00 00       	call   801052fe <memmove>
  log_write(bp);
801017b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017bb:	89 04 24             	mov    %eax,(%esp)
801017be:	e8 3b 20 00 00       	call   801037fe <log_write>
  brelse(bp);
801017c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c6:	89 04 24             	mov    %eax,(%esp)
801017c9:	e8 49 ea ff ff       	call   80100217 <brelse>
}
801017ce:	c9                   	leave  
801017cf:	c3                   	ret    

801017d0 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801017d0:	55                   	push   %ebp
801017d1:	89 e5                	mov    %esp,%ebp
801017d3:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801017d6:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017dd:	e8 f9 37 00 00       	call   80104fdb <acquire>

  // Is the inode already cached?
  empty = 0;
801017e2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017e9:	c7 45 f4 74 12 11 80 	movl   $0x80111274,-0xc(%ebp)
801017f0:	eb 59                	jmp    8010184b <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f5:	8b 40 08             	mov    0x8(%eax),%eax
801017f8:	85 c0                	test   %eax,%eax
801017fa:	7e 35                	jle    80101831 <iget+0x61>
801017fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ff:	8b 00                	mov    (%eax),%eax
80101801:	3b 45 08             	cmp    0x8(%ebp),%eax
80101804:	75 2b                	jne    80101831 <iget+0x61>
80101806:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101809:	8b 40 04             	mov    0x4(%eax),%eax
8010180c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010180f:	75 20                	jne    80101831 <iget+0x61>
      ip->ref++;
80101811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101814:	8b 40 08             	mov    0x8(%eax),%eax
80101817:	8d 50 01             	lea    0x1(%eax),%edx
8010181a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181d:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101820:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101827:	e8 11 38 00 00       	call   8010503d <release>
      return ip;
8010182c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010182f:	eb 6f                	jmp    801018a0 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101831:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101835:	75 10                	jne    80101847 <iget+0x77>
80101837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010183a:	8b 40 08             	mov    0x8(%eax),%eax
8010183d:	85 c0                	test   %eax,%eax
8010183f:	75 06                	jne    80101847 <iget+0x77>
      empty = ip;
80101841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101844:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101847:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010184b:	81 7d f4 14 22 11 80 	cmpl   $0x80112214,-0xc(%ebp)
80101852:	72 9e                	jb     801017f2 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101854:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101858:	75 0c                	jne    80101866 <iget+0x96>
    panic("iget: no inodes");
8010185a:	c7 04 24 dd 86 10 80 	movl   $0x801086dd,(%esp)
80101861:	e8 d4 ec ff ff       	call   8010053a <panic>

  ip = empty;
80101866:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101869:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010186c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010186f:	8b 55 08             	mov    0x8(%ebp),%edx
80101872:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101877:	8b 55 0c             	mov    0xc(%ebp),%edx
8010187a:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010187d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101880:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101887:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010188a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101891:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101898:	e8 a0 37 00 00       	call   8010503d <release>

  return ip;
8010189d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801018a0:	c9                   	leave  
801018a1:	c3                   	ret    

801018a2 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801018a2:	55                   	push   %ebp
801018a3:	89 e5                	mov    %esp,%ebp
801018a5:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801018a8:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018af:	e8 27 37 00 00       	call   80104fdb <acquire>
  ip->ref++;
801018b4:	8b 45 08             	mov    0x8(%ebp),%eax
801018b7:	8b 40 08             	mov    0x8(%eax),%eax
801018ba:	8d 50 01             	lea    0x1(%eax),%edx
801018bd:	8b 45 08             	mov    0x8(%ebp),%eax
801018c0:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801018c3:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018ca:	e8 6e 37 00 00       	call   8010503d <release>
  return ip;
801018cf:	8b 45 08             	mov    0x8(%ebp),%eax
}
801018d2:	c9                   	leave  
801018d3:	c3                   	ret    

801018d4 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801018d4:	55                   	push   %ebp
801018d5:	89 e5                	mov    %esp,%ebp
801018d7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801018da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801018de:	74 0a                	je     801018ea <ilock+0x16>
801018e0:	8b 45 08             	mov    0x8(%ebp),%eax
801018e3:	8b 40 08             	mov    0x8(%eax),%eax
801018e6:	85 c0                	test   %eax,%eax
801018e8:	7f 0c                	jg     801018f6 <ilock+0x22>
    panic("ilock");
801018ea:	c7 04 24 ed 86 10 80 	movl   $0x801086ed,(%esp)
801018f1:	e8 44 ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801018f6:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018fd:	e8 d9 36 00 00       	call   80104fdb <acquire>
  while(ip->flags & I_BUSY)
80101902:	eb 13                	jmp    80101917 <ilock+0x43>
    sleep(ip, &icache.lock);
80101904:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
8010190b:	80 
8010190c:	8b 45 08             	mov    0x8(%ebp),%eax
8010190f:	89 04 24             	mov    %eax,(%esp)
80101912:	e8 fa 33 00 00       	call   80104d11 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101917:	8b 45 08             	mov    0x8(%ebp),%eax
8010191a:	8b 40 0c             	mov    0xc(%eax),%eax
8010191d:	83 e0 01             	and    $0x1,%eax
80101920:	85 c0                	test   %eax,%eax
80101922:	75 e0                	jne    80101904 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101924:	8b 45 08             	mov    0x8(%ebp),%eax
80101927:	8b 40 0c             	mov    0xc(%eax),%eax
8010192a:	83 c8 01             	or     $0x1,%eax
8010192d:	89 c2                	mov    %eax,%edx
8010192f:	8b 45 08             	mov    0x8(%ebp),%eax
80101932:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101935:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
8010193c:	e8 fc 36 00 00       	call   8010503d <release>

  if(!(ip->flags & I_VALID)){
80101941:	8b 45 08             	mov    0x8(%ebp),%eax
80101944:	8b 40 0c             	mov    0xc(%eax),%eax
80101947:	83 e0 02             	and    $0x2,%eax
8010194a:	85 c0                	test   %eax,%eax
8010194c:	0f 85 d4 00 00 00    	jne    80101a26 <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101952:	8b 45 08             	mov    0x8(%ebp),%eax
80101955:	8b 40 04             	mov    0x4(%eax),%eax
80101958:	c1 e8 03             	shr    $0x3,%eax
8010195b:	89 c2                	mov    %eax,%edx
8010195d:	a1 34 12 11 80       	mov    0x80111234,%eax
80101962:	01 c2                	add    %eax,%edx
80101964:	8b 45 08             	mov    0x8(%ebp),%eax
80101967:	8b 00                	mov    (%eax),%eax
80101969:	89 54 24 04          	mov    %edx,0x4(%esp)
8010196d:	89 04 24             	mov    %eax,(%esp)
80101970:	e8 31 e8 ff ff       	call   801001a6 <bread>
80101975:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101978:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010197b:	8d 50 18             	lea    0x18(%eax),%edx
8010197e:	8b 45 08             	mov    0x8(%ebp),%eax
80101981:	8b 40 04             	mov    0x4(%eax),%eax
80101984:	83 e0 07             	and    $0x7,%eax
80101987:	c1 e0 06             	shl    $0x6,%eax
8010198a:	01 d0                	add    %edx,%eax
8010198c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010198f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101992:	0f b7 10             	movzwl (%eax),%edx
80101995:	8b 45 08             	mov    0x8(%ebp),%eax
80101998:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010199c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010199f:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801019a3:	8b 45 08             	mov    0x8(%ebp),%eax
801019a6:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801019aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019ad:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801019b1:	8b 45 08             	mov    0x8(%ebp),%eax
801019b4:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801019b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019bb:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801019bf:	8b 45 08             	mov    0x8(%ebp),%eax
801019c2:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801019c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019c9:	8b 50 08             	mov    0x8(%eax),%edx
801019cc:	8b 45 08             	mov    0x8(%ebp),%eax
801019cf:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801019d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019d5:	8d 50 0c             	lea    0xc(%eax),%edx
801019d8:	8b 45 08             	mov    0x8(%ebp),%eax
801019db:	83 c0 1c             	add    $0x1c,%eax
801019de:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801019e5:	00 
801019e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801019ea:	89 04 24             	mov    %eax,(%esp)
801019ed:	e8 0c 39 00 00       	call   801052fe <memmove>
    brelse(bp);
801019f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019f5:	89 04 24             	mov    %eax,(%esp)
801019f8:	e8 1a e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101a00:	8b 40 0c             	mov    0xc(%eax),%eax
80101a03:	83 c8 02             	or     $0x2,%eax
80101a06:	89 c2                	mov    %eax,%edx
80101a08:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0b:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a11:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a15:	66 85 c0             	test   %ax,%ax
80101a18:	75 0c                	jne    80101a26 <ilock+0x152>
      panic("ilock: no type");
80101a1a:	c7 04 24 f3 86 10 80 	movl   $0x801086f3,(%esp)
80101a21:	e8 14 eb ff ff       	call   8010053a <panic>
  }
}
80101a26:	c9                   	leave  
80101a27:	c3                   	ret    

80101a28 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a28:	55                   	push   %ebp
80101a29:	89 e5                	mov    %esp,%ebp
80101a2b:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101a2e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a32:	74 17                	je     80101a4b <iunlock+0x23>
80101a34:	8b 45 08             	mov    0x8(%ebp),%eax
80101a37:	8b 40 0c             	mov    0xc(%eax),%eax
80101a3a:	83 e0 01             	and    $0x1,%eax
80101a3d:	85 c0                	test   %eax,%eax
80101a3f:	74 0a                	je     80101a4b <iunlock+0x23>
80101a41:	8b 45 08             	mov    0x8(%ebp),%eax
80101a44:	8b 40 08             	mov    0x8(%eax),%eax
80101a47:	85 c0                	test   %eax,%eax
80101a49:	7f 0c                	jg     80101a57 <iunlock+0x2f>
    panic("iunlock");
80101a4b:	c7 04 24 02 87 10 80 	movl   $0x80108702,(%esp)
80101a52:	e8 e3 ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a57:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a5e:	e8 78 35 00 00       	call   80104fdb <acquire>
  ip->flags &= ~I_BUSY;
80101a63:	8b 45 08             	mov    0x8(%ebp),%eax
80101a66:	8b 40 0c             	mov    0xc(%eax),%eax
80101a69:	83 e0 fe             	and    $0xfffffffe,%eax
80101a6c:	89 c2                	mov    %eax,%edx
80101a6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a71:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a74:	8b 45 08             	mov    0x8(%ebp),%eax
80101a77:	89 04 24             	mov    %eax,(%esp)
80101a7a:	e8 6b 33 00 00       	call   80104dea <wakeup>
  release(&icache.lock);
80101a7f:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a86:	e8 b2 35 00 00       	call   8010503d <release>
}
80101a8b:	c9                   	leave  
80101a8c:	c3                   	ret    

80101a8d <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a8d:	55                   	push   %ebp
80101a8e:	89 e5                	mov    %esp,%ebp
80101a90:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a93:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a9a:	e8 3c 35 00 00       	call   80104fdb <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa2:	8b 40 08             	mov    0x8(%eax),%eax
80101aa5:	83 f8 01             	cmp    $0x1,%eax
80101aa8:	0f 85 93 00 00 00    	jne    80101b41 <iput+0xb4>
80101aae:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab1:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab4:	83 e0 02             	and    $0x2,%eax
80101ab7:	85 c0                	test   %eax,%eax
80101ab9:	0f 84 82 00 00 00    	je     80101b41 <iput+0xb4>
80101abf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101ac6:	66 85 c0             	test   %ax,%ax
80101ac9:	75 76                	jne    80101b41 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	8b 40 0c             	mov    0xc(%eax),%eax
80101ad1:	83 e0 01             	and    $0x1,%eax
80101ad4:	85 c0                	test   %eax,%eax
80101ad6:	74 0c                	je     80101ae4 <iput+0x57>
      panic("iput busy");
80101ad8:	c7 04 24 0a 87 10 80 	movl   $0x8010870a,(%esp)
80101adf:	e8 56 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101ae4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae7:	8b 40 0c             	mov    0xc(%eax),%eax
80101aea:	83 c8 01             	or     $0x1,%eax
80101aed:	89 c2                	mov    %eax,%edx
80101aef:	8b 45 08             	mov    0x8(%ebp),%eax
80101af2:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101af5:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101afc:	e8 3c 35 00 00       	call   8010503d <release>
    itrunc(ip);
80101b01:	8b 45 08             	mov    0x8(%ebp),%eax
80101b04:	89 04 24             	mov    %eax,(%esp)
80101b07:	e8 b4 02 00 00       	call   80101dc0 <itrunc>
    ip->type = 0;
80101b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0f:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b15:	8b 45 08             	mov    0x8(%ebp),%eax
80101b18:	89 04 24             	mov    %eax,(%esp)
80101b1b:	e8 f2 fb ff ff       	call   80101712 <iupdate>
    acquire(&icache.lock);
80101b20:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b27:	e8 af 34 00 00       	call   80104fdb <acquire>
    ip->flags = 0;
80101b2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b36:	8b 45 08             	mov    0x8(%ebp),%eax
80101b39:	89 04 24             	mov    %eax,(%esp)
80101b3c:	e8 a9 32 00 00       	call   80104dea <wakeup>
  }
  ip->ref--;
80101b41:	8b 45 08             	mov    0x8(%ebp),%eax
80101b44:	8b 40 08             	mov    0x8(%eax),%eax
80101b47:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4d:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b50:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101b57:	e8 e1 34 00 00       	call   8010503d <release>
}
80101b5c:	c9                   	leave  
80101b5d:	c3                   	ret    

80101b5e <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b5e:	55                   	push   %ebp
80101b5f:	89 e5                	mov    %esp,%ebp
80101b61:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b64:	8b 45 08             	mov    0x8(%ebp),%eax
80101b67:	89 04 24             	mov    %eax,(%esp)
80101b6a:	e8 b9 fe ff ff       	call   80101a28 <iunlock>
  iput(ip);
80101b6f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b72:	89 04 24             	mov    %eax,(%esp)
80101b75:	e8 13 ff ff ff       	call   80101a8d <iput>
}
80101b7a:	c9                   	leave  
80101b7b:	c3                   	ret    

80101b7c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b7c:	55                   	push   %ebp
80101b7d:	89 e5                	mov    %esp,%ebp
80101b7f:	53                   	push   %ebx
80101b80:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b83:	83 7d 0c 0a          	cmpl   $0xa,0xc(%ebp)
80101b87:	77 3e                	ja     80101bc7 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b89:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b8f:	83 c2 04             	add    $0x4,%edx
80101b92:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b96:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b9d:	75 20                	jne    80101bbf <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba2:	8b 00                	mov    (%eax),%eax
80101ba4:	89 04 24             	mov    %eax,(%esp)
80101ba7:	e8 f7 f7 ff ff       	call   801013a3 <balloc>
80101bac:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101baf:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb2:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bb5:	8d 4a 04             	lea    0x4(%edx),%ecx
80101bb8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bbb:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101bbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bc2:	e9 f3 01 00 00       	jmp    80101dba <bmap+0x23e>
  }
  bn -= NDIRECT;
80101bc7:	83 6d 0c 0b          	subl   $0xb,0xc(%ebp)
  if(bn < NINDIRECT){
80101bcb:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101bcf:	0f 87 a5 00 00 00    	ja     80101c7a <bmap+0xfe>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0) 
80101bd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd8:	8b 40 48             	mov    0x48(%eax),%eax
80101bdb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bde:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101be2:	75 19                	jne    80101bfd <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev); //allocate new zeroed disk blocks
80101be4:	8b 45 08             	mov    0x8(%ebp),%eax
80101be7:	8b 00                	mov    (%eax),%eax
80101be9:	89 04 24             	mov    %eax,(%esp)
80101bec:	e8 b2 f7 ff ff       	call   801013a3 <balloc>
80101bf1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bf4:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bfa:	89 50 48             	mov    %edx,0x48(%eax)
    bp = bread(ip->dev, addr);//bread reads the contents of a disk block
80101bfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101c00:	8b 00                	mov    (%eax),%eax
80101c02:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c05:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c09:	89 04 24             	mov    %eax,(%esp)
80101c0c:	e8 95 e5 ff ff       	call   801001a6 <bread>
80101c11:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;//grab the data
80101c14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c17:	83 c0 18             	add    $0x18,%eax
80101c1a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c20:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c27:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c2a:	01 d0                	add    %edx,%eax
80101c2c:	8b 00                	mov    (%eax),%eax
80101c2e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c31:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c35:	75 30                	jne    80101c67 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);//allocate new zeroes disk blocks
80101c37:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c3a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c44:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101c47:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4a:	8b 00                	mov    (%eax),%eax
80101c4c:	89 04 24             	mov    %eax,(%esp)
80101c4f:	e8 4f f7 ff ff       	call   801013a3 <balloc>
80101c54:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c5a:	89 03                	mov    %eax,(%ebx)
      log_write(bp);//pointer to each struct buf containing modified data
80101c5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c5f:	89 04 24             	mov    %eax,(%esp)
80101c62:	e8 97 1b 00 00       	call   801037fe <log_write>
    }
    brelse(bp);
80101c67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c6a:	89 04 24             	mov    %eax,(%esp)
80101c6d:	e8 a5 e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c75:	e9 40 01 00 00       	jmp    80101dba <bmap+0x23e>
  }
  bn -= NINDIRECT;
80101c7a:	83 45 0c 80          	addl   $0xffffff80,0xc(%ebp)
  if(bn < NDINDIRECT){
80101c7e:	81 7d 0c ff 3f 00 00 	cmpl   $0x3fff,0xc(%ebp)
80101c85:	0f 87 23 01 00 00    	ja     80101dae <bmap+0x232>
    /*
    Go to second block get index vector then get 1st index for indirection
    then release the double indirect then get 2nd level of the table
    */
    if((addr = ip->addrs[NDIRECT+1]) == 0) 
80101c8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c91:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c94:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c98:	75 19                	jne    80101cb3 <bmap+0x137>
      ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
80101c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9d:	8b 00                	mov    (%eax),%eax
80101c9f:	89 04 24             	mov    %eax,(%esp)
80101ca2:	e8 fc f6 ff ff       	call   801013a3 <balloc>
80101ca7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101caa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cad:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cb0:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb6:	8b 00                	mov    (%eax),%eax
80101cb8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cbb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cbf:	89 04 24             	mov    %eax,(%esp)
80101cc2:	e8 df e4 ff ff       	call   801001a6 <bread>
80101cc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101cca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ccd:	83 c0 18             	add    $0x18,%eax
80101cd0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if ((addr = a[bn/(NINDIRECT)]) == 0) {      
80101cd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cd6:	c1 e8 07             	shr    $0x7,%eax
80101cd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce3:	01 d0                	add    %edx,%eax
80101ce5:	8b 00                	mov    (%eax),%eax
80101ce7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cee:	75 33                	jne    80101d23 <bmap+0x1a7>
      a[bn/(NINDIRECT)] = addr = balloc(ip->dev);
80101cf0:	8b 45 0c             	mov    0xc(%ebp),%eax
80101cf3:	c1 e8 07             	shr    $0x7,%eax
80101cf6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cfd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d00:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d03:	8b 45 08             	mov    0x8(%ebp),%eax
80101d06:	8b 00                	mov    (%eax),%eax
80101d08:	89 04 24             	mov    %eax,(%esp)
80101d0b:	e8 93 f6 ff ff       	call   801013a3 <balloc>
80101d10:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d16:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d1b:	89 04 24             	mov    %eax,(%esp)
80101d1e:	e8 db 1a 00 00       	call   801037fe <log_write>
    }
    brelse(bp);           
80101d23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d26:	89 04 24             	mov    %eax,(%esp)
80101d29:	e8 e9 e4 ff ff       	call   80100217 <brelse>
    bp = bread(ip->dev, addr);
80101d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d31:	8b 00                	mov    (%eax),%eax
80101d33:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d36:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d3a:	89 04 24             	mov    %eax,(%esp)
80101d3d:	e8 64 e4 ff ff       	call   801001a6 <bread>
80101d42:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101d45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d48:	83 c0 18             	add    $0x18,%eax
80101d4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn%(NINDIRECT)]) == 0) { 
80101d4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d51:	83 e0 7f             	and    $0x7f,%eax
80101d54:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d5b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d5e:	01 d0                	add    %edx,%eax
80101d60:	8b 00                	mov    (%eax),%eax
80101d62:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d65:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d69:	75 33                	jne    80101d9e <bmap+0x222>
      a[bn%(NINDIRECT)] = addr = balloc(ip->dev);
80101d6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d6e:	83 e0 7f             	and    $0x7f,%eax
80101d71:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d78:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d7b:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d81:	8b 00                	mov    (%eax),%eax
80101d83:	89 04 24             	mov    %eax,(%esp)
80101d86:	e8 18 f6 ff ff       	call   801013a3 <balloc>
80101d8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d91:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d96:	89 04 24             	mov    %eax,(%esp)
80101d99:	e8 60 1a 00 00       	call   801037fe <log_write>
    }
    brelse(bp);
80101d9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da1:	89 04 24             	mov    %eax,(%esp)
80101da4:	e8 6e e4 ff ff       	call   80100217 <brelse>
    return addr;
80101da9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dac:	eb 0c                	jmp    80101dba <bmap+0x23e>
  }
  panic("bmap: out of range");
80101dae:	c7 04 24 14 87 10 80 	movl   $0x80108714,(%esp)
80101db5:	e8 80 e7 ff ff       	call   8010053a <panic>
}
80101dba:	83 c4 24             	add    $0x24,%esp
80101dbd:	5b                   	pop    %ebx
80101dbe:	5d                   	pop    %ebp
80101dbf:	c3                   	ret    

80101dc0 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101dc0:	55                   	push   %ebp
80101dc1:	89 e5                	mov    %esp,%ebp
80101dc3:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101dc6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101dcd:	eb 44                	jmp    80101e13 <itrunc+0x53>
    if(ip->addrs[i]){
80101dcf:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dd5:	83 c2 04             	add    $0x4,%edx
80101dd8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101ddc:	85 c0                	test   %eax,%eax
80101dde:	74 2f                	je     80101e0f <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101de0:	8b 45 08             	mov    0x8(%ebp),%eax
80101de3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101de6:	83 c2 04             	add    $0x4,%edx
80101de9:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101ded:	8b 45 08             	mov    0x8(%ebp),%eax
80101df0:	8b 00                	mov    (%eax),%eax
80101df2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101df6:	89 04 24             	mov    %eax,(%esp)
80101df9:	e8 e3 f6 ff ff       	call   801014e1 <bfree>
      ip->addrs[i] = 0;
80101dfe:	8b 45 08             	mov    0x8(%ebp),%eax
80101e01:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101e04:	83 c2 04             	add    $0x4,%edx
80101e07:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101e0e:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101e0f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e13:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
80101e17:	7e b6                	jle    80101dcf <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101e19:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1c:	8b 40 48             	mov    0x48(%eax),%eax
80101e1f:	85 c0                	test   %eax,%eax
80101e21:	0f 84 9b 00 00 00    	je     80101ec2 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101e27:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2a:	8b 50 48             	mov    0x48(%eax),%edx
80101e2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e30:	8b 00                	mov    (%eax),%eax
80101e32:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e36:	89 04 24             	mov    %eax,(%esp)
80101e39:	e8 68 e3 ff ff       	call   801001a6 <bread>
80101e3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e44:	83 c0 18             	add    $0x18,%eax
80101e47:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e4a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e51:	eb 3b                	jmp    80101e8e <itrunc+0xce>
      if(a[j])
80101e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e56:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e5d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e60:	01 d0                	add    %edx,%eax
80101e62:	8b 00                	mov    (%eax),%eax
80101e64:	85 c0                	test   %eax,%eax
80101e66:	74 22                	je     80101e8a <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101e68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e6b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e72:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e75:	01 d0                	add    %edx,%eax
80101e77:	8b 10                	mov    (%eax),%edx
80101e79:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7c:	8b 00                	mov    (%eax),%eax
80101e7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e82:	89 04 24             	mov    %eax,(%esp)
80101e85:	e8 57 f6 ff ff       	call   801014e1 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e8a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e91:	83 f8 7f             	cmp    $0x7f,%eax
80101e94:	76 bd                	jbe    80101e53 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e96:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e99:	89 04 24             	mov    %eax,(%esp)
80101e9c:	e8 76 e3 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ea1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea4:	8b 50 48             	mov    0x48(%eax),%edx
80101ea7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eaa:	8b 00                	mov    (%eax),%eax
80101eac:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eb0:	89 04 24             	mov    %eax,(%esp)
80101eb3:	e8 29 f6 ff ff       	call   801014e1 <bfree>
    ip->addrs[NDIRECT] = 0;
80101eb8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ebb:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
  }
  ip->size = 0;
80101ec2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec5:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101ecc:	8b 45 08             	mov    0x8(%ebp),%eax
80101ecf:	89 04 24             	mov    %eax,(%esp)
80101ed2:	e8 3b f8 ff ff       	call   80101712 <iupdate>
}
80101ed7:	c9                   	leave  
80101ed8:	c3                   	ret    

80101ed9 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101ed9:	55                   	push   %ebp
80101eda:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101edc:	8b 45 08             	mov    0x8(%ebp),%eax
80101edf:	8b 00                	mov    (%eax),%eax
80101ee1:	89 c2                	mov    %eax,%edx
80101ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee6:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101ee9:	8b 45 08             	mov    0x8(%ebp),%eax
80101eec:	8b 50 04             	mov    0x4(%eax),%edx
80101eef:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ef2:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef8:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101efc:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eff:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101f02:	8b 45 08             	mov    0x8(%ebp),%eax
80101f05:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101f09:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f0c:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101f10:	8b 45 08             	mov    0x8(%ebp),%eax
80101f13:	8b 50 18             	mov    0x18(%eax),%edx
80101f16:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f19:	89 50 10             	mov    %edx,0x10(%eax)
}
80101f1c:	5d                   	pop    %ebp
80101f1d:	c3                   	ret    

80101f1e <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101f1e:	55                   	push   %ebp
80101f1f:	89 e5                	mov    %esp,%ebp
80101f21:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f24:	8b 45 08             	mov    0x8(%ebp),%eax
80101f27:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f2b:	66 83 f8 03          	cmp    $0x3,%ax
80101f2f:	75 60                	jne    80101f91 <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f31:	8b 45 08             	mov    0x8(%ebp),%eax
80101f34:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f38:	66 85 c0             	test   %ax,%ax
80101f3b:	78 20                	js     80101f5d <readi+0x3f>
80101f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f40:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f44:	66 83 f8 09          	cmp    $0x9,%ax
80101f48:	7f 13                	jg     80101f5d <readi+0x3f>
80101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f51:	98                   	cwtl   
80101f52:	8b 04 c5 c0 11 11 80 	mov    -0x7feeee40(,%eax,8),%eax
80101f59:	85 c0                	test   %eax,%eax
80101f5b:	75 0a                	jne    80101f67 <readi+0x49>
      return -1;
80101f5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f62:	e9 19 01 00 00       	jmp    80102080 <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101f67:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f6e:	98                   	cwtl   
80101f6f:	8b 04 c5 c0 11 11 80 	mov    -0x7feeee40(,%eax,8),%eax
80101f76:	8b 55 14             	mov    0x14(%ebp),%edx
80101f79:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f7d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f80:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f84:	8b 55 08             	mov    0x8(%ebp),%edx
80101f87:	89 14 24             	mov    %edx,(%esp)
80101f8a:	ff d0                	call   *%eax
80101f8c:	e9 ef 00 00 00       	jmp    80102080 <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101f91:	8b 45 08             	mov    0x8(%ebp),%eax
80101f94:	8b 40 18             	mov    0x18(%eax),%eax
80101f97:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f9a:	72 0d                	jb     80101fa9 <readi+0x8b>
80101f9c:	8b 45 14             	mov    0x14(%ebp),%eax
80101f9f:	8b 55 10             	mov    0x10(%ebp),%edx
80101fa2:	01 d0                	add    %edx,%eax
80101fa4:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fa7:	73 0a                	jae    80101fb3 <readi+0x95>
    return -1;
80101fa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fae:	e9 cd 00 00 00       	jmp    80102080 <readi+0x162>
  if(off + n > ip->size)
80101fb3:	8b 45 14             	mov    0x14(%ebp),%eax
80101fb6:	8b 55 10             	mov    0x10(%ebp),%edx
80101fb9:	01 c2                	add    %eax,%edx
80101fbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbe:	8b 40 18             	mov    0x18(%eax),%eax
80101fc1:	39 c2                	cmp    %eax,%edx
80101fc3:	76 0c                	jbe    80101fd1 <readi+0xb3>
    n = ip->size - off;
80101fc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc8:	8b 40 18             	mov    0x18(%eax),%eax
80101fcb:	2b 45 10             	sub    0x10(%ebp),%eax
80101fce:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fd1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fd8:	e9 94 00 00 00       	jmp    80102071 <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fdd:	8b 45 10             	mov    0x10(%ebp),%eax
80101fe0:	c1 e8 09             	shr    $0x9,%eax
80101fe3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80101fea:	89 04 24             	mov    %eax,(%esp)
80101fed:	e8 8a fb ff ff       	call   80101b7c <bmap>
80101ff2:	8b 55 08             	mov    0x8(%ebp),%edx
80101ff5:	8b 12                	mov    (%edx),%edx
80101ff7:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ffb:	89 14 24             	mov    %edx,(%esp)
80101ffe:	e8 a3 e1 ff ff       	call   801001a6 <bread>
80102003:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102006:	8b 45 10             	mov    0x10(%ebp),%eax
80102009:	25 ff 01 00 00       	and    $0x1ff,%eax
8010200e:	89 c2                	mov    %eax,%edx
80102010:	b8 00 02 00 00       	mov    $0x200,%eax
80102015:	29 d0                	sub    %edx,%eax
80102017:	89 c2                	mov    %eax,%edx
80102019:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010201c:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010201f:	29 c1                	sub    %eax,%ecx
80102021:	89 c8                	mov    %ecx,%eax
80102023:	39 c2                	cmp    %eax,%edx
80102025:	0f 46 c2             	cmovbe %edx,%eax
80102028:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
8010202b:	8b 45 10             	mov    0x10(%ebp),%eax
8010202e:	25 ff 01 00 00       	and    $0x1ff,%eax
80102033:	8d 50 10             	lea    0x10(%eax),%edx
80102036:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102039:	01 d0                	add    %edx,%eax
8010203b:	8d 50 08             	lea    0x8(%eax),%edx
8010203e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102041:	89 44 24 08          	mov    %eax,0x8(%esp)
80102045:	89 54 24 04          	mov    %edx,0x4(%esp)
80102049:	8b 45 0c             	mov    0xc(%ebp),%eax
8010204c:	89 04 24             	mov    %eax,(%esp)
8010204f:	e8 aa 32 00 00       	call   801052fe <memmove>
    brelse(bp);
80102054:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102057:	89 04 24             	mov    %eax,(%esp)
8010205a:	e8 b8 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010205f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102062:	01 45 f4             	add    %eax,-0xc(%ebp)
80102065:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102068:	01 45 10             	add    %eax,0x10(%ebp)
8010206b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010206e:	01 45 0c             	add    %eax,0xc(%ebp)
80102071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102074:	3b 45 14             	cmp    0x14(%ebp),%eax
80102077:	0f 82 60 ff ff ff    	jb     80101fdd <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010207d:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102080:	c9                   	leave  
80102081:	c3                   	ret    

80102082 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102082:	55                   	push   %ebp
80102083:	89 e5                	mov    %esp,%ebp
80102085:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102088:	8b 45 08             	mov    0x8(%ebp),%eax
8010208b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010208f:	66 83 f8 03          	cmp    $0x3,%ax
80102093:	75 60                	jne    801020f5 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102095:	8b 45 08             	mov    0x8(%ebp),%eax
80102098:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010209c:	66 85 c0             	test   %ax,%ax
8010209f:	78 20                	js     801020c1 <writei+0x3f>
801020a1:	8b 45 08             	mov    0x8(%ebp),%eax
801020a4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020a8:	66 83 f8 09          	cmp    $0x9,%ax
801020ac:	7f 13                	jg     801020c1 <writei+0x3f>
801020ae:	8b 45 08             	mov    0x8(%ebp),%eax
801020b1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020b5:	98                   	cwtl   
801020b6:	8b 04 c5 c4 11 11 80 	mov    -0x7feeee3c(,%eax,8),%eax
801020bd:	85 c0                	test   %eax,%eax
801020bf:	75 0a                	jne    801020cb <writei+0x49>
      return -1;
801020c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020c6:	e9 44 01 00 00       	jmp    8010220f <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
801020cb:	8b 45 08             	mov    0x8(%ebp),%eax
801020ce:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020d2:	98                   	cwtl   
801020d3:	8b 04 c5 c4 11 11 80 	mov    -0x7feeee3c(,%eax,8),%eax
801020da:	8b 55 14             	mov    0x14(%ebp),%edx
801020dd:	89 54 24 08          	mov    %edx,0x8(%esp)
801020e1:	8b 55 0c             	mov    0xc(%ebp),%edx
801020e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801020e8:	8b 55 08             	mov    0x8(%ebp),%edx
801020eb:	89 14 24             	mov    %edx,(%esp)
801020ee:	ff d0                	call   *%eax
801020f0:	e9 1a 01 00 00       	jmp    8010220f <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801020f5:	8b 45 08             	mov    0x8(%ebp),%eax
801020f8:	8b 40 18             	mov    0x18(%eax),%eax
801020fb:	3b 45 10             	cmp    0x10(%ebp),%eax
801020fe:	72 0d                	jb     8010210d <writei+0x8b>
80102100:	8b 45 14             	mov    0x14(%ebp),%eax
80102103:	8b 55 10             	mov    0x10(%ebp),%edx
80102106:	01 d0                	add    %edx,%eax
80102108:	3b 45 10             	cmp    0x10(%ebp),%eax
8010210b:	73 0a                	jae    80102117 <writei+0x95>
    return -1;
8010210d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102112:	e9 f8 00 00 00       	jmp    8010220f <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80102117:	8b 45 14             	mov    0x14(%ebp),%eax
8010211a:	8b 55 10             	mov    0x10(%ebp),%edx
8010211d:	01 d0                	add    %edx,%eax
8010211f:	3d 00 16 81 00       	cmp    $0x811600,%eax
80102124:	76 0a                	jbe    80102130 <writei+0xae>
    return -1;
80102126:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010212b:	e9 df 00 00 00       	jmp    8010220f <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102130:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102137:	e9 9f 00 00 00       	jmp    801021db <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010213c:	8b 45 10             	mov    0x10(%ebp),%eax
8010213f:	c1 e8 09             	shr    $0x9,%eax
80102142:	89 44 24 04          	mov    %eax,0x4(%esp)
80102146:	8b 45 08             	mov    0x8(%ebp),%eax
80102149:	89 04 24             	mov    %eax,(%esp)
8010214c:	e8 2b fa ff ff       	call   80101b7c <bmap>
80102151:	8b 55 08             	mov    0x8(%ebp),%edx
80102154:	8b 12                	mov    (%edx),%edx
80102156:	89 44 24 04          	mov    %eax,0x4(%esp)
8010215a:	89 14 24             	mov    %edx,(%esp)
8010215d:	e8 44 e0 ff ff       	call   801001a6 <bread>
80102162:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102165:	8b 45 10             	mov    0x10(%ebp),%eax
80102168:	25 ff 01 00 00       	and    $0x1ff,%eax
8010216d:	89 c2                	mov    %eax,%edx
8010216f:	b8 00 02 00 00       	mov    $0x200,%eax
80102174:	29 d0                	sub    %edx,%eax
80102176:	89 c2                	mov    %eax,%edx
80102178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010217b:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010217e:	29 c1                	sub    %eax,%ecx
80102180:	89 c8                	mov    %ecx,%eax
80102182:	39 c2                	cmp    %eax,%edx
80102184:	0f 46 c2             	cmovbe %edx,%eax
80102187:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010218a:	8b 45 10             	mov    0x10(%ebp),%eax
8010218d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102192:	8d 50 10             	lea    0x10(%eax),%edx
80102195:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102198:	01 d0                	add    %edx,%eax
8010219a:	8d 50 08             	lea    0x8(%eax),%edx
8010219d:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801021a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801021a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ab:	89 14 24             	mov    %edx,(%esp)
801021ae:	e8 4b 31 00 00       	call   801052fe <memmove>
    log_write(bp);
801021b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b6:	89 04 24             	mov    %eax,(%esp)
801021b9:	e8 40 16 00 00       	call   801037fe <log_write>
    brelse(bp);
801021be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c1:	89 04 24             	mov    %eax,(%esp)
801021c4:	e8 4e e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801021c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021cc:	01 45 f4             	add    %eax,-0xc(%ebp)
801021cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d2:	01 45 10             	add    %eax,0x10(%ebp)
801021d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d8:	01 45 0c             	add    %eax,0xc(%ebp)
801021db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021de:	3b 45 14             	cmp    0x14(%ebp),%eax
801021e1:	0f 82 55 ff ff ff    	jb     8010213c <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801021e7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021eb:	74 1f                	je     8010220c <writei+0x18a>
801021ed:	8b 45 08             	mov    0x8(%ebp),%eax
801021f0:	8b 40 18             	mov    0x18(%eax),%eax
801021f3:	3b 45 10             	cmp    0x10(%ebp),%eax
801021f6:	73 14                	jae    8010220c <writei+0x18a>
    ip->size = off;
801021f8:	8b 45 08             	mov    0x8(%ebp),%eax
801021fb:	8b 55 10             	mov    0x10(%ebp),%edx
801021fe:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102201:	8b 45 08             	mov    0x8(%ebp),%eax
80102204:	89 04 24             	mov    %eax,(%esp)
80102207:	e8 06 f5 ff ff       	call   80101712 <iupdate>
  }
  return n;
8010220c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010220f:	c9                   	leave  
80102210:	c3                   	ret    

80102211 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102211:	55                   	push   %ebp
80102212:	89 e5                	mov    %esp,%ebp
80102214:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102217:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010221e:	00 
8010221f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102222:	89 44 24 04          	mov    %eax,0x4(%esp)
80102226:	8b 45 08             	mov    0x8(%ebp),%eax
80102229:	89 04 24             	mov    %eax,(%esp)
8010222c:	e8 70 31 00 00       	call   801053a1 <strncmp>
}
80102231:	c9                   	leave  
80102232:	c3                   	ret    

80102233 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102233:	55                   	push   %ebp
80102234:	89 e5                	mov    %esp,%ebp
80102236:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102239:	8b 45 08             	mov    0x8(%ebp),%eax
8010223c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102240:	66 83 f8 01          	cmp    $0x1,%ax
80102244:	74 0c                	je     80102252 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102246:	c7 04 24 27 87 10 80 	movl   $0x80108727,(%esp)
8010224d:	e8 e8 e2 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102252:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102259:	e9 88 00 00 00       	jmp    801022e6 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010225e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102265:	00 
80102266:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102269:	89 44 24 08          	mov    %eax,0x8(%esp)
8010226d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102270:	89 44 24 04          	mov    %eax,0x4(%esp)
80102274:	8b 45 08             	mov    0x8(%ebp),%eax
80102277:	89 04 24             	mov    %eax,(%esp)
8010227a:	e8 9f fc ff ff       	call   80101f1e <readi>
8010227f:	83 f8 10             	cmp    $0x10,%eax
80102282:	74 0c                	je     80102290 <dirlookup+0x5d>
      panic("dirlink read");
80102284:	c7 04 24 39 87 10 80 	movl   $0x80108739,(%esp)
8010228b:	e8 aa e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102290:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102294:	66 85 c0             	test   %ax,%ax
80102297:	75 02                	jne    8010229b <dirlookup+0x68>
      continue;
80102299:	eb 47                	jmp    801022e2 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
8010229b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010229e:	83 c0 02             	add    $0x2,%eax
801022a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801022a8:	89 04 24             	mov    %eax,(%esp)
801022ab:	e8 61 ff ff ff       	call   80102211 <namecmp>
801022b0:	85 c0                	test   %eax,%eax
801022b2:	75 2e                	jne    801022e2 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801022b4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801022b8:	74 08                	je     801022c2 <dirlookup+0x8f>
        *poff = off;
801022ba:	8b 45 10             	mov    0x10(%ebp),%eax
801022bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022c0:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801022c2:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022c6:	0f b7 c0             	movzwl %ax,%eax
801022c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801022cc:	8b 45 08             	mov    0x8(%ebp),%eax
801022cf:	8b 00                	mov    (%eax),%eax
801022d1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801022d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801022d8:	89 04 24             	mov    %eax,(%esp)
801022db:	e8 f0 f4 ff ff       	call   801017d0 <iget>
801022e0:	eb 18                	jmp    801022fa <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801022e2:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022e6:	8b 45 08             	mov    0x8(%ebp),%eax
801022e9:	8b 40 18             	mov    0x18(%eax),%eax
801022ec:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022ef:	0f 87 69 ff ff ff    	ja     8010225e <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801022f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022fa:	c9                   	leave  
801022fb:	c3                   	ret    

801022fc <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022fc:	55                   	push   %ebp
801022fd:	89 e5                	mov    %esp,%ebp
801022ff:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102302:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102309:	00 
8010230a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010230d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102311:	8b 45 08             	mov    0x8(%ebp),%eax
80102314:	89 04 24             	mov    %eax,(%esp)
80102317:	e8 17 ff ff ff       	call   80102233 <dirlookup>
8010231c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010231f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102323:	74 15                	je     8010233a <dirlink+0x3e>
    iput(ip);
80102325:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102328:	89 04 24             	mov    %eax,(%esp)
8010232b:	e8 5d f7 ff ff       	call   80101a8d <iput>
    return -1;
80102330:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102335:	e9 b7 00 00 00       	jmp    801023f1 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010233a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102341:	eb 46                	jmp    80102389 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102346:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010234d:	00 
8010234e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102352:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102355:	89 44 24 04          	mov    %eax,0x4(%esp)
80102359:	8b 45 08             	mov    0x8(%ebp),%eax
8010235c:	89 04 24             	mov    %eax,(%esp)
8010235f:	e8 ba fb ff ff       	call   80101f1e <readi>
80102364:	83 f8 10             	cmp    $0x10,%eax
80102367:	74 0c                	je     80102375 <dirlink+0x79>
      panic("dirlink read");
80102369:	c7 04 24 39 87 10 80 	movl   $0x80108739,(%esp)
80102370:	e8 c5 e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102375:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102379:	66 85 c0             	test   %ax,%ax
8010237c:	75 02                	jne    80102380 <dirlink+0x84>
      break;
8010237e:	eb 16                	jmp    80102396 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102380:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102383:	83 c0 10             	add    $0x10,%eax
80102386:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102389:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010238c:	8b 45 08             	mov    0x8(%ebp),%eax
8010238f:	8b 40 18             	mov    0x18(%eax),%eax
80102392:	39 c2                	cmp    %eax,%edx
80102394:	72 ad                	jb     80102343 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102396:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010239d:	00 
8010239e:	8b 45 0c             	mov    0xc(%ebp),%eax
801023a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801023a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023a8:	83 c0 02             	add    $0x2,%eax
801023ab:	89 04 24             	mov    %eax,(%esp)
801023ae:	e8 44 30 00 00       	call   801053f7 <strncpy>
  de.inum = inum;
801023b3:	8b 45 10             	mov    0x10(%ebp),%eax
801023b6:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023bd:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023c4:	00 
801023c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801023c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d0:	8b 45 08             	mov    0x8(%ebp),%eax
801023d3:	89 04 24             	mov    %eax,(%esp)
801023d6:	e8 a7 fc ff ff       	call   80102082 <writei>
801023db:	83 f8 10             	cmp    $0x10,%eax
801023de:	74 0c                	je     801023ec <dirlink+0xf0>
    panic("dirlink");
801023e0:	c7 04 24 46 87 10 80 	movl   $0x80108746,(%esp)
801023e7:	e8 4e e1 ff ff       	call   8010053a <panic>
  
  return 0;
801023ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
801023f1:	c9                   	leave  
801023f2:	c3                   	ret    

801023f3 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801023f3:	55                   	push   %ebp
801023f4:	89 e5                	mov    %esp,%ebp
801023f6:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801023f9:	eb 04                	jmp    801023ff <skipelem+0xc>
    path++;
801023fb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801023ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102402:	0f b6 00             	movzbl (%eax),%eax
80102405:	3c 2f                	cmp    $0x2f,%al
80102407:	74 f2                	je     801023fb <skipelem+0x8>
    path++;
  if(*path == 0)
80102409:	8b 45 08             	mov    0x8(%ebp),%eax
8010240c:	0f b6 00             	movzbl (%eax),%eax
8010240f:	84 c0                	test   %al,%al
80102411:	75 0a                	jne    8010241d <skipelem+0x2a>
    return 0;
80102413:	b8 00 00 00 00       	mov    $0x0,%eax
80102418:	e9 86 00 00 00       	jmp    801024a3 <skipelem+0xb0>
  s = path;
8010241d:	8b 45 08             	mov    0x8(%ebp),%eax
80102420:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102423:	eb 04                	jmp    80102429 <skipelem+0x36>
    path++;
80102425:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102429:	8b 45 08             	mov    0x8(%ebp),%eax
8010242c:	0f b6 00             	movzbl (%eax),%eax
8010242f:	3c 2f                	cmp    $0x2f,%al
80102431:	74 0a                	je     8010243d <skipelem+0x4a>
80102433:	8b 45 08             	mov    0x8(%ebp),%eax
80102436:	0f b6 00             	movzbl (%eax),%eax
80102439:	84 c0                	test   %al,%al
8010243b:	75 e8                	jne    80102425 <skipelem+0x32>
    path++;
  len = path - s;
8010243d:	8b 55 08             	mov    0x8(%ebp),%edx
80102440:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102443:	29 c2                	sub    %eax,%edx
80102445:	89 d0                	mov    %edx,%eax
80102447:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010244a:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010244e:	7e 1c                	jle    8010246c <skipelem+0x79>
    memmove(name, s, DIRSIZ);
80102450:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102457:	00 
80102458:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010245b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010245f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102462:	89 04 24             	mov    %eax,(%esp)
80102465:	e8 94 2e 00 00       	call   801052fe <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010246a:	eb 2a                	jmp    80102496 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010246c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010246f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102476:	89 44 24 04          	mov    %eax,0x4(%esp)
8010247a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010247d:	89 04 24             	mov    %eax,(%esp)
80102480:	e8 79 2e 00 00       	call   801052fe <memmove>
    name[len] = 0;
80102485:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102488:	8b 45 0c             	mov    0xc(%ebp),%eax
8010248b:	01 d0                	add    %edx,%eax
8010248d:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102490:	eb 04                	jmp    80102496 <skipelem+0xa3>
    path++;
80102492:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102496:	8b 45 08             	mov    0x8(%ebp),%eax
80102499:	0f b6 00             	movzbl (%eax),%eax
8010249c:	3c 2f                	cmp    $0x2f,%al
8010249e:	74 f2                	je     80102492 <skipelem+0x9f>
    path++;
  return path;
801024a0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801024a3:	c9                   	leave  
801024a4:	c3                   	ret    

801024a5 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801024a5:	55                   	push   %ebp
801024a6:	89 e5                	mov    %esp,%ebp
801024a8:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801024ab:	8b 45 08             	mov    0x8(%ebp),%eax
801024ae:	0f b6 00             	movzbl (%eax),%eax
801024b1:	3c 2f                	cmp    $0x2f,%al
801024b3:	75 1c                	jne    801024d1 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801024b5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024bc:	00 
801024bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024c4:	e8 07 f3 ff ff       	call   801017d0 <iget>
801024c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024cc:	e9 af 00 00 00       	jmp    80102580 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024d7:	8b 40 68             	mov    0x68(%eax),%eax
801024da:	89 04 24             	mov    %eax,(%esp)
801024dd:	e8 c0 f3 ff ff       	call   801018a2 <idup>
801024e2:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801024e5:	e9 96 00 00 00       	jmp    80102580 <namex+0xdb>
    ilock(ip);
801024ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ed:	89 04 24             	mov    %eax,(%esp)
801024f0:	e8 df f3 ff ff       	call   801018d4 <ilock>
    if(ip->type != T_DIR){
801024f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024f8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801024fc:	66 83 f8 01          	cmp    $0x1,%ax
80102500:	74 15                	je     80102517 <namex+0x72>
      iunlockput(ip);
80102502:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102505:	89 04 24             	mov    %eax,(%esp)
80102508:	e8 51 f6 ff ff       	call   80101b5e <iunlockput>
      return 0;
8010250d:	b8 00 00 00 00       	mov    $0x0,%eax
80102512:	e9 a3 00 00 00       	jmp    801025ba <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102517:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010251b:	74 1d                	je     8010253a <namex+0x95>
8010251d:	8b 45 08             	mov    0x8(%ebp),%eax
80102520:	0f b6 00             	movzbl (%eax),%eax
80102523:	84 c0                	test   %al,%al
80102525:	75 13                	jne    8010253a <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102527:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010252a:	89 04 24             	mov    %eax,(%esp)
8010252d:	e8 f6 f4 ff ff       	call   80101a28 <iunlock>
      return ip;
80102532:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102535:	e9 80 00 00 00       	jmp    801025ba <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
8010253a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102541:	00 
80102542:	8b 45 10             	mov    0x10(%ebp),%eax
80102545:	89 44 24 04          	mov    %eax,0x4(%esp)
80102549:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010254c:	89 04 24             	mov    %eax,(%esp)
8010254f:	e8 df fc ff ff       	call   80102233 <dirlookup>
80102554:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102557:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010255b:	75 12                	jne    8010256f <namex+0xca>
      iunlockput(ip);
8010255d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102560:	89 04 24             	mov    %eax,(%esp)
80102563:	e8 f6 f5 ff ff       	call   80101b5e <iunlockput>
      return 0;
80102568:	b8 00 00 00 00       	mov    $0x0,%eax
8010256d:	eb 4b                	jmp    801025ba <namex+0x115>
    }
    iunlockput(ip);
8010256f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102572:	89 04 24             	mov    %eax,(%esp)
80102575:	e8 e4 f5 ff ff       	call   80101b5e <iunlockput>
    ip = next;
8010257a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010257d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102580:	8b 45 10             	mov    0x10(%ebp),%eax
80102583:	89 44 24 04          	mov    %eax,0x4(%esp)
80102587:	8b 45 08             	mov    0x8(%ebp),%eax
8010258a:	89 04 24             	mov    %eax,(%esp)
8010258d:	e8 61 fe ff ff       	call   801023f3 <skipelem>
80102592:	89 45 08             	mov    %eax,0x8(%ebp)
80102595:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102599:	0f 85 4b ff ff ff    	jne    801024ea <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010259f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025a3:	74 12                	je     801025b7 <namex+0x112>
    iput(ip);
801025a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a8:	89 04 24             	mov    %eax,(%esp)
801025ab:	e8 dd f4 ff ff       	call   80101a8d <iput>
    return 0;
801025b0:	b8 00 00 00 00       	mov    $0x0,%eax
801025b5:	eb 03                	jmp    801025ba <namex+0x115>
  }
  return ip;
801025b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801025ba:	c9                   	leave  
801025bb:	c3                   	ret    

801025bc <namei>:

struct inode*
namei(char *path)
{
801025bc:	55                   	push   %ebp
801025bd:	89 e5                	mov    %esp,%ebp
801025bf:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801025c2:	8d 45 ea             	lea    -0x16(%ebp),%eax
801025c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801025c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025d0:	00 
801025d1:	8b 45 08             	mov    0x8(%ebp),%eax
801025d4:	89 04 24             	mov    %eax,(%esp)
801025d7:	e8 c9 fe ff ff       	call   801024a5 <namex>
}
801025dc:	c9                   	leave  
801025dd:	c3                   	ret    

801025de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801025de:	55                   	push   %ebp
801025df:	89 e5                	mov    %esp,%ebp
801025e1:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801025e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801025e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801025eb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801025f2:	00 
801025f3:	8b 45 08             	mov    0x8(%ebp),%eax
801025f6:	89 04 24             	mov    %eax,(%esp)
801025f9:	e8 a7 fe ff ff       	call   801024a5 <namex>
}
801025fe:	c9                   	leave  
801025ff:	c3                   	ret    

80102600 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102600:	55                   	push   %ebp
80102601:	89 e5                	mov    %esp,%ebp
80102603:	83 ec 14             	sub    $0x14,%esp
80102606:	8b 45 08             	mov    0x8(%ebp),%eax
80102609:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010260d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102611:	89 c2                	mov    %eax,%edx
80102613:	ec                   	in     (%dx),%al
80102614:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102617:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010261b:	c9                   	leave  
8010261c:	c3                   	ret    

8010261d <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010261d:	55                   	push   %ebp
8010261e:	89 e5                	mov    %esp,%ebp
80102620:	57                   	push   %edi
80102621:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102622:	8b 55 08             	mov    0x8(%ebp),%edx
80102625:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102628:	8b 45 10             	mov    0x10(%ebp),%eax
8010262b:	89 cb                	mov    %ecx,%ebx
8010262d:	89 df                	mov    %ebx,%edi
8010262f:	89 c1                	mov    %eax,%ecx
80102631:	fc                   	cld    
80102632:	f3 6d                	rep insl (%dx),%es:(%edi)
80102634:	89 c8                	mov    %ecx,%eax
80102636:	89 fb                	mov    %edi,%ebx
80102638:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010263b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010263e:	5b                   	pop    %ebx
8010263f:	5f                   	pop    %edi
80102640:	5d                   	pop    %ebp
80102641:	c3                   	ret    

80102642 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102642:	55                   	push   %ebp
80102643:	89 e5                	mov    %esp,%ebp
80102645:	83 ec 08             	sub    $0x8,%esp
80102648:	8b 55 08             	mov    0x8(%ebp),%edx
8010264b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010264e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102652:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102655:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102659:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010265d:	ee                   	out    %al,(%dx)
}
8010265e:	c9                   	leave  
8010265f:	c3                   	ret    

80102660 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102660:	55                   	push   %ebp
80102661:	89 e5                	mov    %esp,%ebp
80102663:	56                   	push   %esi
80102664:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102665:	8b 55 08             	mov    0x8(%ebp),%edx
80102668:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010266b:	8b 45 10             	mov    0x10(%ebp),%eax
8010266e:	89 cb                	mov    %ecx,%ebx
80102670:	89 de                	mov    %ebx,%esi
80102672:	89 c1                	mov    %eax,%ecx
80102674:	fc                   	cld    
80102675:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102677:	89 c8                	mov    %ecx,%eax
80102679:	89 f3                	mov    %esi,%ebx
8010267b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010267e:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102681:	5b                   	pop    %ebx
80102682:	5e                   	pop    %esi
80102683:	5d                   	pop    %ebp
80102684:	c3                   	ret    

80102685 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102685:	55                   	push   %ebp
80102686:	89 e5                	mov    %esp,%ebp
80102688:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010268b:	90                   	nop
8010268c:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102693:	e8 68 ff ff ff       	call   80102600 <inb>
80102698:	0f b6 c0             	movzbl %al,%eax
8010269b:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010269e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026a1:	25 c0 00 00 00       	and    $0xc0,%eax
801026a6:	83 f8 40             	cmp    $0x40,%eax
801026a9:	75 e1                	jne    8010268c <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801026ab:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026af:	74 11                	je     801026c2 <idewait+0x3d>
801026b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026b4:	83 e0 21             	and    $0x21,%eax
801026b7:	85 c0                	test   %eax,%eax
801026b9:	74 07                	je     801026c2 <idewait+0x3d>
    return -1;
801026bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801026c0:	eb 05                	jmp    801026c7 <idewait+0x42>
  return 0;
801026c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801026c7:	c9                   	leave  
801026c8:	c3                   	ret    

801026c9 <ideinit>:

void
ideinit(void)
{
801026c9:	55                   	push   %ebp
801026ca:	89 e5                	mov    %esp,%ebp
801026cc:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
801026cf:	c7 44 24 04 4e 87 10 	movl   $0x8010874e,0x4(%esp)
801026d6:	80 
801026d7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801026de:	e8 d7 28 00 00       	call   80104fba <initlock>
  picenable(IRQ_IDE);
801026e3:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801026ea:	e8 a3 18 00 00       	call   80103f92 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801026ef:	a1 40 29 11 80       	mov    0x80112940,%eax
801026f4:	83 e8 01             	sub    $0x1,%eax
801026f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801026fb:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102702:	e8 43 04 00 00       	call   80102b4a <ioapicenable>
  idewait(0);
80102707:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010270e:	e8 72 ff ff ff       	call   80102685 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102713:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010271a:	00 
8010271b:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102722:	e8 1b ff ff ff       	call   80102642 <outb>
  for(i=0; i<1000; i++){
80102727:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010272e:	eb 20                	jmp    80102750 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102730:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102737:	e8 c4 fe ff ff       	call   80102600 <inb>
8010273c:	84 c0                	test   %al,%al
8010273e:	74 0c                	je     8010274c <ideinit+0x83>
      havedisk1 = 1;
80102740:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102747:	00 00 00 
      break;
8010274a:	eb 0d                	jmp    80102759 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
8010274c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102750:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102757:	7e d7                	jle    80102730 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102759:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102760:	00 
80102761:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102768:	e8 d5 fe ff ff       	call   80102642 <outb>
}
8010276d:	c9                   	leave  
8010276e:	c3                   	ret    

8010276f <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010276f:	55                   	push   %ebp
80102770:	89 e5                	mov    %esp,%ebp
80102772:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102775:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102779:	75 0c                	jne    80102787 <idestart+0x18>
    panic("idestart");
8010277b:	c7 04 24 52 87 10 80 	movl   $0x80108752,(%esp)
80102782:	e8 b3 dd ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102787:	8b 45 08             	mov    0x8(%ebp),%eax
8010278a:	8b 40 08             	mov    0x8(%eax),%eax
8010278d:	3d 3f 42 0f 00       	cmp    $0xf423f,%eax
80102792:	76 0c                	jbe    801027a0 <idestart+0x31>
    panic("incorrect blockno");
80102794:	c7 04 24 5b 87 10 80 	movl   $0x8010875b,(%esp)
8010279b:	e8 9a dd ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
801027a0:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
801027a7:	8b 45 08             	mov    0x8(%ebp),%eax
801027aa:	8b 50 08             	mov    0x8(%eax),%edx
801027ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b0:	0f af c2             	imul   %edx,%eax
801027b3:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
801027b6:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
801027ba:	7e 0c                	jle    801027c8 <idestart+0x59>
801027bc:	c7 04 24 52 87 10 80 	movl   $0x80108752,(%esp)
801027c3:	e8 72 dd ff ff       	call   8010053a <panic>
  
  idewait(0);
801027c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801027cf:	e8 b1 fe ff ff       	call   80102685 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801027d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801027db:	00 
801027dc:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801027e3:	e8 5a fe ff ff       	call   80102642 <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
801027e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027eb:	0f b6 c0             	movzbl %al,%eax
801027ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801027f2:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801027f9:	e8 44 fe ff ff       	call   80102642 <outb>
  outb(0x1f3, sector & 0xff);
801027fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102801:	0f b6 c0             	movzbl %al,%eax
80102804:	89 44 24 04          	mov    %eax,0x4(%esp)
80102808:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
8010280f:	e8 2e fe ff ff       	call   80102642 <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102814:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102817:	c1 f8 08             	sar    $0x8,%eax
8010281a:	0f b6 c0             	movzbl %al,%eax
8010281d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102821:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102828:	e8 15 fe ff ff       	call   80102642 <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
8010282d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102830:	c1 f8 10             	sar    $0x10,%eax
80102833:	0f b6 c0             	movzbl %al,%eax
80102836:	89 44 24 04          	mov    %eax,0x4(%esp)
8010283a:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102841:	e8 fc fd ff ff       	call   80102642 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102846:	8b 45 08             	mov    0x8(%ebp),%eax
80102849:	8b 40 04             	mov    0x4(%eax),%eax
8010284c:	83 e0 01             	and    $0x1,%eax
8010284f:	c1 e0 04             	shl    $0x4,%eax
80102852:	89 c2                	mov    %eax,%edx
80102854:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102857:	c1 f8 18             	sar    $0x18,%eax
8010285a:	83 e0 0f             	and    $0xf,%eax
8010285d:	09 d0                	or     %edx,%eax
8010285f:	83 c8 e0             	or     $0xffffffe0,%eax
80102862:	0f b6 c0             	movzbl %al,%eax
80102865:	89 44 24 04          	mov    %eax,0x4(%esp)
80102869:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102870:	e8 cd fd ff ff       	call   80102642 <outb>
  if(b->flags & B_DIRTY){
80102875:	8b 45 08             	mov    0x8(%ebp),%eax
80102878:	8b 00                	mov    (%eax),%eax
8010287a:	83 e0 04             	and    $0x4,%eax
8010287d:	85 c0                	test   %eax,%eax
8010287f:	74 34                	je     801028b5 <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102881:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102888:	00 
80102889:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102890:	e8 ad fd ff ff       	call   80102642 <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102895:	8b 45 08             	mov    0x8(%ebp),%eax
80102898:	83 c0 18             	add    $0x18,%eax
8010289b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801028a2:	00 
801028a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801028a7:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801028ae:	e8 ad fd ff ff       	call   80102660 <outsl>
801028b3:	eb 14                	jmp    801028c9 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801028b5:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801028bc:	00 
801028bd:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028c4:	e8 79 fd ff ff       	call   80102642 <outb>
  }
}
801028c9:	c9                   	leave  
801028ca:	c3                   	ret    

801028cb <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801028cb:	55                   	push   %ebp
801028cc:	89 e5                	mov    %esp,%ebp
801028ce:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801028d1:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028d8:	e8 fe 26 00 00       	call   80104fdb <acquire>
  if((b = idequeue) == 0){
801028dd:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801028e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801028e9:	75 11                	jne    801028fc <ideintr+0x31>
    release(&idelock);
801028eb:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028f2:	e8 46 27 00 00       	call   8010503d <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801028f7:	e9 90 00 00 00       	jmp    8010298c <ideintr+0xc1>
  }
  idequeue = b->qnext;
801028fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ff:	8b 40 14             	mov    0x14(%eax),%eax
80102902:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010290a:	8b 00                	mov    (%eax),%eax
8010290c:	83 e0 04             	and    $0x4,%eax
8010290f:	85 c0                	test   %eax,%eax
80102911:	75 2e                	jne    80102941 <ideintr+0x76>
80102913:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010291a:	e8 66 fd ff ff       	call   80102685 <idewait>
8010291f:	85 c0                	test   %eax,%eax
80102921:	78 1e                	js     80102941 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102926:	83 c0 18             	add    $0x18,%eax
80102929:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102930:	00 
80102931:	89 44 24 04          	mov    %eax,0x4(%esp)
80102935:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010293c:	e8 dc fc ff ff       	call   8010261d <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102941:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102944:	8b 00                	mov    (%eax),%eax
80102946:	83 c8 02             	or     $0x2,%eax
80102949:	89 c2                	mov    %eax,%edx
8010294b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010294e:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102953:	8b 00                	mov    (%eax),%eax
80102955:	83 e0 fb             	and    $0xfffffffb,%eax
80102958:	89 c2                	mov    %eax,%edx
8010295a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010295d:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010295f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102962:	89 04 24             	mov    %eax,(%esp)
80102965:	e8 80 24 00 00       	call   80104dea <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
8010296a:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010296f:	85 c0                	test   %eax,%eax
80102971:	74 0d                	je     80102980 <ideintr+0xb5>
    idestart(idequeue);
80102973:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102978:	89 04 24             	mov    %eax,(%esp)
8010297b:	e8 ef fd ff ff       	call   8010276f <idestart>

  release(&idelock);
80102980:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102987:	e8 b1 26 00 00       	call   8010503d <release>
}
8010298c:	c9                   	leave  
8010298d:	c3                   	ret    

8010298e <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010298e:	55                   	push   %ebp
8010298f:	89 e5                	mov    %esp,%ebp
80102991:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102994:	8b 45 08             	mov    0x8(%ebp),%eax
80102997:	8b 00                	mov    (%eax),%eax
80102999:	83 e0 01             	and    $0x1,%eax
8010299c:	85 c0                	test   %eax,%eax
8010299e:	75 0c                	jne    801029ac <iderw+0x1e>
    panic("iderw: buf not busy");
801029a0:	c7 04 24 6d 87 10 80 	movl   $0x8010876d,(%esp)
801029a7:	e8 8e db ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801029ac:	8b 45 08             	mov    0x8(%ebp),%eax
801029af:	8b 00                	mov    (%eax),%eax
801029b1:	83 e0 06             	and    $0x6,%eax
801029b4:	83 f8 02             	cmp    $0x2,%eax
801029b7:	75 0c                	jne    801029c5 <iderw+0x37>
    panic("iderw: nothing to do");
801029b9:	c7 04 24 81 87 10 80 	movl   $0x80108781,(%esp)
801029c0:	e8 75 db ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801029c5:	8b 45 08             	mov    0x8(%ebp),%eax
801029c8:	8b 40 04             	mov    0x4(%eax),%eax
801029cb:	85 c0                	test   %eax,%eax
801029cd:	74 15                	je     801029e4 <iderw+0x56>
801029cf:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801029d4:	85 c0                	test   %eax,%eax
801029d6:	75 0c                	jne    801029e4 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801029d8:	c7 04 24 96 87 10 80 	movl   $0x80108796,(%esp)
801029df:	e8 56 db ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
801029e4:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801029eb:	e8 eb 25 00 00       	call   80104fdb <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801029f0:	8b 45 08             	mov    0x8(%ebp),%eax
801029f3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801029fa:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102a01:	eb 0b                	jmp    80102a0e <iderw+0x80>
80102a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a06:	8b 00                	mov    (%eax),%eax
80102a08:	83 c0 14             	add    $0x14,%eax
80102a0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a11:	8b 00                	mov    (%eax),%eax
80102a13:	85 c0                	test   %eax,%eax
80102a15:	75 ec                	jne    80102a03 <iderw+0x75>
    ;
  *pp = b;
80102a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a1a:	8b 55 08             	mov    0x8(%ebp),%edx
80102a1d:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102a1f:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102a24:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a27:	75 0d                	jne    80102a36 <iderw+0xa8>
    idestart(b);
80102a29:	8b 45 08             	mov    0x8(%ebp),%eax
80102a2c:	89 04 24             	mov    %eax,(%esp)
80102a2f:	e8 3b fd ff ff       	call   8010276f <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a34:	eb 15                	jmp    80102a4b <iderw+0xbd>
80102a36:	eb 13                	jmp    80102a4b <iderw+0xbd>
    sleep(b, &idelock);
80102a38:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
80102a3f:	80 
80102a40:	8b 45 08             	mov    0x8(%ebp),%eax
80102a43:	89 04 24             	mov    %eax,(%esp)
80102a46:	e8 c6 22 00 00       	call   80104d11 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a4b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a4e:	8b 00                	mov    (%eax),%eax
80102a50:	83 e0 06             	and    $0x6,%eax
80102a53:	83 f8 02             	cmp    $0x2,%eax
80102a56:	75 e0                	jne    80102a38 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102a58:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102a5f:	e8 d9 25 00 00       	call   8010503d <release>
}
80102a64:	c9                   	leave  
80102a65:	c3                   	ret    

80102a66 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a66:	55                   	push   %ebp
80102a67:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a69:	a1 14 22 11 80       	mov    0x80112214,%eax
80102a6e:	8b 55 08             	mov    0x8(%ebp),%edx
80102a71:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a73:	a1 14 22 11 80       	mov    0x80112214,%eax
80102a78:	8b 40 10             	mov    0x10(%eax),%eax
}
80102a7b:	5d                   	pop    %ebp
80102a7c:	c3                   	ret    

80102a7d <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102a7d:	55                   	push   %ebp
80102a7e:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a80:	a1 14 22 11 80       	mov    0x80112214,%eax
80102a85:	8b 55 08             	mov    0x8(%ebp),%edx
80102a88:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102a8a:	a1 14 22 11 80       	mov    0x80112214,%eax
80102a8f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a92:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a95:	5d                   	pop    %ebp
80102a96:	c3                   	ret    

80102a97 <ioapicinit>:

void
ioapicinit(void)
{
80102a97:	55                   	push   %ebp
80102a98:	89 e5                	mov    %esp,%ebp
80102a9a:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102a9d:	a1 44 23 11 80       	mov    0x80112344,%eax
80102aa2:	85 c0                	test   %eax,%eax
80102aa4:	75 05                	jne    80102aab <ioapicinit+0x14>
    return;
80102aa6:	e9 9d 00 00 00       	jmp    80102b48 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102aab:	c7 05 14 22 11 80 00 	movl   $0xfec00000,0x80112214
80102ab2:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102ab5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102abc:	e8 a5 ff ff ff       	call   80102a66 <ioapicread>
80102ac1:	c1 e8 10             	shr    $0x10,%eax
80102ac4:	25 ff 00 00 00       	and    $0xff,%eax
80102ac9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102acc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102ad3:	e8 8e ff ff ff       	call   80102a66 <ioapicread>
80102ad8:	c1 e8 18             	shr    $0x18,%eax
80102adb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102ade:	0f b6 05 40 23 11 80 	movzbl 0x80112340,%eax
80102ae5:	0f b6 c0             	movzbl %al,%eax
80102ae8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102aeb:	74 0c                	je     80102af9 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102aed:	c7 04 24 b4 87 10 80 	movl   $0x801087b4,(%esp)
80102af4:	e8 a7 d8 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102af9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b00:	eb 3e                	jmp    80102b40 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102b02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b05:	83 c0 20             	add    $0x20,%eax
80102b08:	0d 00 00 01 00       	or     $0x10000,%eax
80102b0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b10:	83 c2 08             	add    $0x8,%edx
80102b13:	01 d2                	add    %edx,%edx
80102b15:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b19:	89 14 24             	mov    %edx,(%esp)
80102b1c:	e8 5c ff ff ff       	call   80102a7d <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b24:	83 c0 08             	add    $0x8,%eax
80102b27:	01 c0                	add    %eax,%eax
80102b29:	83 c0 01             	add    $0x1,%eax
80102b2c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b33:	00 
80102b34:	89 04 24             	mov    %eax,(%esp)
80102b37:	e8 41 ff ff ff       	call   80102a7d <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b3c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b43:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b46:	7e ba                	jle    80102b02 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b48:	c9                   	leave  
80102b49:	c3                   	ret    

80102b4a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b4a:	55                   	push   %ebp
80102b4b:	89 e5                	mov    %esp,%ebp
80102b4d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102b50:	a1 44 23 11 80       	mov    0x80112344,%eax
80102b55:	85 c0                	test   %eax,%eax
80102b57:	75 02                	jne    80102b5b <ioapicenable+0x11>
    return;
80102b59:	eb 37                	jmp    80102b92 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b5b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b5e:	83 c0 20             	add    $0x20,%eax
80102b61:	8b 55 08             	mov    0x8(%ebp),%edx
80102b64:	83 c2 08             	add    $0x8,%edx
80102b67:	01 d2                	add    %edx,%edx
80102b69:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b6d:	89 14 24             	mov    %edx,(%esp)
80102b70:	e8 08 ff ff ff       	call   80102a7d <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b75:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b78:	c1 e0 18             	shl    $0x18,%eax
80102b7b:	8b 55 08             	mov    0x8(%ebp),%edx
80102b7e:	83 c2 08             	add    $0x8,%edx
80102b81:	01 d2                	add    %edx,%edx
80102b83:	83 c2 01             	add    $0x1,%edx
80102b86:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b8a:	89 14 24             	mov    %edx,(%esp)
80102b8d:	e8 eb fe ff ff       	call   80102a7d <ioapicwrite>
}
80102b92:	c9                   	leave  
80102b93:	c3                   	ret    

80102b94 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102b94:	55                   	push   %ebp
80102b95:	89 e5                	mov    %esp,%ebp
80102b97:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9a:	05 00 00 00 80       	add    $0x80000000,%eax
80102b9f:	5d                   	pop    %ebp
80102ba0:	c3                   	ret    

80102ba1 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102ba1:	55                   	push   %ebp
80102ba2:	89 e5                	mov    %esp,%ebp
80102ba4:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102ba7:	c7 44 24 04 e6 87 10 	movl   $0x801087e6,0x4(%esp)
80102bae:	80 
80102baf:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102bb6:	e8 ff 23 00 00       	call   80104fba <initlock>
  kmem.use_lock = 0;
80102bbb:	c7 05 54 22 11 80 00 	movl   $0x0,0x80112254
80102bc2:	00 00 00 
  freerange(vstart, vend);
80102bc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcf:	89 04 24             	mov    %eax,(%esp)
80102bd2:	e8 26 00 00 00       	call   80102bfd <freerange>
}
80102bd7:	c9                   	leave  
80102bd8:	c3                   	ret    

80102bd9 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102bd9:	55                   	push   %ebp
80102bda:	89 e5                	mov    %esp,%ebp
80102bdc:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102bdf:	8b 45 0c             	mov    0xc(%ebp),%eax
80102be2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102be6:	8b 45 08             	mov    0x8(%ebp),%eax
80102be9:	89 04 24             	mov    %eax,(%esp)
80102bec:	e8 0c 00 00 00       	call   80102bfd <freerange>
  kmem.use_lock = 1;
80102bf1:	c7 05 54 22 11 80 01 	movl   $0x1,0x80112254
80102bf8:	00 00 00 
}
80102bfb:	c9                   	leave  
80102bfc:	c3                   	ret    

80102bfd <freerange>:

void
freerange(void *vstart, void *vend)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
80102c00:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102c03:	8b 45 08             	mov    0x8(%ebp),%eax
80102c06:	05 ff 0f 00 00       	add    $0xfff,%eax
80102c0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102c10:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c13:	eb 12                	jmp    80102c27 <freerange+0x2a>
    kfree(p);
80102c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c18:	89 04 24             	mov    %eax,(%esp)
80102c1b:	e8 16 00 00 00       	call   80102c36 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c20:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c2a:	05 00 10 00 00       	add    $0x1000,%eax
80102c2f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102c32:	76 e1                	jbe    80102c15 <freerange+0x18>
    kfree(p);
}
80102c34:	c9                   	leave  
80102c35:	c3                   	ret    

80102c36 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102c36:	55                   	push   %ebp
80102c37:	89 e5                	mov    %esp,%ebp
80102c39:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102c3c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c3f:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c44:	85 c0                	test   %eax,%eax
80102c46:	75 1b                	jne    80102c63 <kfree+0x2d>
80102c48:	81 7d 08 3c 51 11 80 	cmpl   $0x8011513c,0x8(%ebp)
80102c4f:	72 12                	jb     80102c63 <kfree+0x2d>
80102c51:	8b 45 08             	mov    0x8(%ebp),%eax
80102c54:	89 04 24             	mov    %eax,(%esp)
80102c57:	e8 38 ff ff ff       	call   80102b94 <v2p>
80102c5c:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c61:	76 0c                	jbe    80102c6f <kfree+0x39>
    panic("kfree");
80102c63:	c7 04 24 eb 87 10 80 	movl   $0x801087eb,(%esp)
80102c6a:	e8 cb d8 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c6f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102c76:	00 
80102c77:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102c7e:	00 
80102c7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c82:	89 04 24             	mov    %eax,(%esp)
80102c85:	e8 a5 25 00 00       	call   8010522f <memset>

  if(kmem.use_lock)
80102c8a:	a1 54 22 11 80       	mov    0x80112254,%eax
80102c8f:	85 c0                	test   %eax,%eax
80102c91:	74 0c                	je     80102c9f <kfree+0x69>
    acquire(&kmem.lock);
80102c93:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102c9a:	e8 3c 23 00 00       	call   80104fdb <acquire>
  r = (struct run*)v;
80102c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ca5:	8b 15 58 22 11 80    	mov    0x80112258,%edx
80102cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cae:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102cb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb3:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102cb8:	a1 54 22 11 80       	mov    0x80112254,%eax
80102cbd:	85 c0                	test   %eax,%eax
80102cbf:	74 0c                	je     80102ccd <kfree+0x97>
    release(&kmem.lock);
80102cc1:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102cc8:	e8 70 23 00 00       	call   8010503d <release>
}
80102ccd:	c9                   	leave  
80102cce:	c3                   	ret    

80102ccf <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102ccf:	55                   	push   %ebp
80102cd0:	89 e5                	mov    %esp,%ebp
80102cd2:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102cd5:	a1 54 22 11 80       	mov    0x80112254,%eax
80102cda:	85 c0                	test   %eax,%eax
80102cdc:	74 0c                	je     80102cea <kalloc+0x1b>
    acquire(&kmem.lock);
80102cde:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102ce5:	e8 f1 22 00 00       	call   80104fdb <acquire>
  r = kmem.freelist;
80102cea:	a1 58 22 11 80       	mov    0x80112258,%eax
80102cef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102cf2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102cf6:	74 0a                	je     80102d02 <kalloc+0x33>
    kmem.freelist = r->next;
80102cf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cfb:	8b 00                	mov    (%eax),%eax
80102cfd:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102d02:	a1 54 22 11 80       	mov    0x80112254,%eax
80102d07:	85 c0                	test   %eax,%eax
80102d09:	74 0c                	je     80102d17 <kalloc+0x48>
    release(&kmem.lock);
80102d0b:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102d12:	e8 26 23 00 00       	call   8010503d <release>
  return (char*)r;
80102d17:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102d1a:	c9                   	leave  
80102d1b:	c3                   	ret    

80102d1c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d1c:	55                   	push   %ebp
80102d1d:	89 e5                	mov    %esp,%ebp
80102d1f:	83 ec 14             	sub    $0x14,%esp
80102d22:	8b 45 08             	mov    0x8(%ebp),%eax
80102d25:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d29:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102d2d:	89 c2                	mov    %eax,%edx
80102d2f:	ec                   	in     (%dx),%al
80102d30:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d33:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d37:	c9                   	leave  
80102d38:	c3                   	ret    

80102d39 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d39:	55                   	push   %ebp
80102d3a:	89 e5                	mov    %esp,%ebp
80102d3c:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d3f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102d46:	e8 d1 ff ff ff       	call   80102d1c <inb>
80102d4b:	0f b6 c0             	movzbl %al,%eax
80102d4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d54:	83 e0 01             	and    $0x1,%eax
80102d57:	85 c0                	test   %eax,%eax
80102d59:	75 0a                	jne    80102d65 <kbdgetc+0x2c>
    return -1;
80102d5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d60:	e9 25 01 00 00       	jmp    80102e8a <kbdgetc+0x151>
  data = inb(KBDATAP);
80102d65:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102d6c:	e8 ab ff ff ff       	call   80102d1c <inb>
80102d71:	0f b6 c0             	movzbl %al,%eax
80102d74:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d77:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d7e:	75 17                	jne    80102d97 <kbdgetc+0x5e>
    shift |= E0ESC;
80102d80:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d85:	83 c8 40             	or     $0x40,%eax
80102d88:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102d8d:	b8 00 00 00 00       	mov    $0x0,%eax
80102d92:	e9 f3 00 00 00       	jmp    80102e8a <kbdgetc+0x151>
  } else if(data & 0x80){
80102d97:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d9a:	25 80 00 00 00       	and    $0x80,%eax
80102d9f:	85 c0                	test   %eax,%eax
80102da1:	74 45                	je     80102de8 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102da3:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102da8:	83 e0 40             	and    $0x40,%eax
80102dab:	85 c0                	test   %eax,%eax
80102dad:	75 08                	jne    80102db7 <kbdgetc+0x7e>
80102daf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102db2:	83 e0 7f             	and    $0x7f,%eax
80102db5:	eb 03                	jmp    80102dba <kbdgetc+0x81>
80102db7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dba:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102dbd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dc0:	05 20 90 10 80       	add    $0x80109020,%eax
80102dc5:	0f b6 00             	movzbl (%eax),%eax
80102dc8:	83 c8 40             	or     $0x40,%eax
80102dcb:	0f b6 c0             	movzbl %al,%eax
80102dce:	f7 d0                	not    %eax
80102dd0:	89 c2                	mov    %eax,%edx
80102dd2:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102dd7:	21 d0                	and    %edx,%eax
80102dd9:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102dde:	b8 00 00 00 00       	mov    $0x0,%eax
80102de3:	e9 a2 00 00 00       	jmp    80102e8a <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102de8:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ded:	83 e0 40             	and    $0x40,%eax
80102df0:	85 c0                	test   %eax,%eax
80102df2:	74 14                	je     80102e08 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102df4:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102dfb:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e00:	83 e0 bf             	and    $0xffffffbf,%eax
80102e03:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102e08:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e0b:	05 20 90 10 80       	add    $0x80109020,%eax
80102e10:	0f b6 00             	movzbl (%eax),%eax
80102e13:	0f b6 d0             	movzbl %al,%edx
80102e16:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e1b:	09 d0                	or     %edx,%eax
80102e1d:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102e22:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e25:	05 20 91 10 80       	add    $0x80109120,%eax
80102e2a:	0f b6 00             	movzbl (%eax),%eax
80102e2d:	0f b6 d0             	movzbl %al,%edx
80102e30:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e35:	31 d0                	xor    %edx,%eax
80102e37:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e3c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e41:	83 e0 03             	and    $0x3,%eax
80102e44:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102e4b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e4e:	01 d0                	add    %edx,%eax
80102e50:	0f b6 00             	movzbl (%eax),%eax
80102e53:	0f b6 c0             	movzbl %al,%eax
80102e56:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e59:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102e5e:	83 e0 08             	and    $0x8,%eax
80102e61:	85 c0                	test   %eax,%eax
80102e63:	74 22                	je     80102e87 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102e65:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e69:	76 0c                	jbe    80102e77 <kbdgetc+0x13e>
80102e6b:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e6f:	77 06                	ja     80102e77 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102e71:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e75:	eb 10                	jmp    80102e87 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102e77:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e7b:	76 0a                	jbe    80102e87 <kbdgetc+0x14e>
80102e7d:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e81:	77 04                	ja     80102e87 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102e83:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e87:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e8a:	c9                   	leave  
80102e8b:	c3                   	ret    

80102e8c <kbdintr>:

void
kbdintr(void)
{
80102e8c:	55                   	push   %ebp
80102e8d:	89 e5                	mov    %esp,%ebp
80102e8f:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102e92:	c7 04 24 39 2d 10 80 	movl   $0x80102d39,(%esp)
80102e99:	e8 2a d9 ff ff       	call   801007c8 <consoleintr>
}
80102e9e:	c9                   	leave  
80102e9f:	c3                   	ret    

80102ea0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ea0:	55                   	push   %ebp
80102ea1:	89 e5                	mov    %esp,%ebp
80102ea3:	83 ec 14             	sub    $0x14,%esp
80102ea6:	8b 45 08             	mov    0x8(%ebp),%eax
80102ea9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ead:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102eb1:	89 c2                	mov    %eax,%edx
80102eb3:	ec                   	in     (%dx),%al
80102eb4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102eb7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102ebb:	c9                   	leave  
80102ebc:	c3                   	ret    

80102ebd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102ebd:	55                   	push   %ebp
80102ebe:	89 e5                	mov    %esp,%ebp
80102ec0:	83 ec 08             	sub    $0x8,%esp
80102ec3:	8b 55 08             	mov    0x8(%ebp),%edx
80102ec6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ec9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102ecd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ed0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ed4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102ed8:	ee                   	out    %al,(%dx)
}
80102ed9:	c9                   	leave  
80102eda:	c3                   	ret    

80102edb <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102edb:	55                   	push   %ebp
80102edc:	89 e5                	mov    %esp,%ebp
80102ede:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102ee1:	9c                   	pushf  
80102ee2:	58                   	pop    %eax
80102ee3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102ee6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102ee9:	c9                   	leave  
80102eea:	c3                   	ret    

80102eeb <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102eeb:	55                   	push   %ebp
80102eec:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102eee:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102ef3:	8b 55 08             	mov    0x8(%ebp),%edx
80102ef6:	c1 e2 02             	shl    $0x2,%edx
80102ef9:	01 c2                	add    %eax,%edx
80102efb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102efe:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102f00:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f05:	83 c0 20             	add    $0x20,%eax
80102f08:	8b 00                	mov    (%eax),%eax
}
80102f0a:	5d                   	pop    %ebp
80102f0b:	c3                   	ret    

80102f0c <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102f0c:	55                   	push   %ebp
80102f0d:	89 e5                	mov    %esp,%ebp
80102f0f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102f12:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f17:	85 c0                	test   %eax,%eax
80102f19:	75 05                	jne    80102f20 <lapicinit+0x14>
    return;
80102f1b:	e9 43 01 00 00       	jmp    80103063 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102f20:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102f27:	00 
80102f28:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102f2f:	e8 b7 ff ff ff       	call   80102eeb <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102f34:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102f3b:	00 
80102f3c:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102f43:	e8 a3 ff ff ff       	call   80102eeb <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102f48:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102f4f:	00 
80102f50:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f57:	e8 8f ff ff ff       	call   80102eeb <lapicw>
  lapicw(TICR, 10000000); 
80102f5c:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102f63:	00 
80102f64:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102f6b:	e8 7b ff ff ff       	call   80102eeb <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f70:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f77:	00 
80102f78:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102f7f:	e8 67 ff ff ff       	call   80102eeb <lapicw>
  lapicw(LINT1, MASKED);
80102f84:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f8b:	00 
80102f8c:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102f93:	e8 53 ff ff ff       	call   80102eeb <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f98:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f9d:	83 c0 30             	add    $0x30,%eax
80102fa0:	8b 00                	mov    (%eax),%eax
80102fa2:	c1 e8 10             	shr    $0x10,%eax
80102fa5:	0f b6 c0             	movzbl %al,%eax
80102fa8:	83 f8 03             	cmp    $0x3,%eax
80102fab:	76 14                	jbe    80102fc1 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102fad:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fb4:	00 
80102fb5:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102fbc:	e8 2a ff ff ff       	call   80102eeb <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102fc1:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102fc8:	00 
80102fc9:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102fd0:	e8 16 ff ff ff       	call   80102eeb <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102fd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fdc:	00 
80102fdd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102fe4:	e8 02 ff ff ff       	call   80102eeb <lapicw>
  lapicw(ESR, 0);
80102fe9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ff0:	00 
80102ff1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102ff8:	e8 ee fe ff ff       	call   80102eeb <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102ffd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103004:	00 
80103005:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010300c:	e8 da fe ff ff       	call   80102eeb <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103011:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103018:	00 
80103019:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103020:	e8 c6 fe ff ff       	call   80102eeb <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103025:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010302c:	00 
8010302d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103034:	e8 b2 fe ff ff       	call   80102eeb <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103039:	90                   	nop
8010303a:	a1 5c 22 11 80       	mov    0x8011225c,%eax
8010303f:	05 00 03 00 00       	add    $0x300,%eax
80103044:	8b 00                	mov    (%eax),%eax
80103046:	25 00 10 00 00       	and    $0x1000,%eax
8010304b:	85 c0                	test   %eax,%eax
8010304d:	75 eb                	jne    8010303a <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
8010304f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103056:	00 
80103057:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010305e:	e8 88 fe ff ff       	call   80102eeb <lapicw>
}
80103063:	c9                   	leave  
80103064:	c3                   	ret    

80103065 <cpunum>:

int
cpunum(void)
{
80103065:	55                   	push   %ebp
80103066:	89 e5                	mov    %esp,%ebp
80103068:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010306b:	e8 6b fe ff ff       	call   80102edb <readeflags>
80103070:	25 00 02 00 00       	and    $0x200,%eax
80103075:	85 c0                	test   %eax,%eax
80103077:	74 25                	je     8010309e <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103079:	a1 40 b6 10 80       	mov    0x8010b640,%eax
8010307e:	8d 50 01             	lea    0x1(%eax),%edx
80103081:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
80103087:	85 c0                	test   %eax,%eax
80103089:	75 13                	jne    8010309e <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
8010308b:	8b 45 04             	mov    0x4(%ebp),%eax
8010308e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103092:	c7 04 24 f4 87 10 80 	movl   $0x801087f4,(%esp)
80103099:	e8 02 d3 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010309e:	a1 5c 22 11 80       	mov    0x8011225c,%eax
801030a3:	85 c0                	test   %eax,%eax
801030a5:	74 0f                	je     801030b6 <cpunum+0x51>
    return lapic[ID]>>24;
801030a7:	a1 5c 22 11 80       	mov    0x8011225c,%eax
801030ac:	83 c0 20             	add    $0x20,%eax
801030af:	8b 00                	mov    (%eax),%eax
801030b1:	c1 e8 18             	shr    $0x18,%eax
801030b4:	eb 05                	jmp    801030bb <cpunum+0x56>
  return 0;
801030b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030bb:	c9                   	leave  
801030bc:	c3                   	ret    

801030bd <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801030bd:	55                   	push   %ebp
801030be:	89 e5                	mov    %esp,%ebp
801030c0:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801030c3:	a1 5c 22 11 80       	mov    0x8011225c,%eax
801030c8:	85 c0                	test   %eax,%eax
801030ca:	74 14                	je     801030e0 <lapiceoi+0x23>
    lapicw(EOI, 0);
801030cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030d3:	00 
801030d4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801030db:	e8 0b fe ff ff       	call   80102eeb <lapicw>
}
801030e0:	c9                   	leave  
801030e1:	c3                   	ret    

801030e2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801030e2:	55                   	push   %ebp
801030e3:	89 e5                	mov    %esp,%ebp
}
801030e5:	5d                   	pop    %ebp
801030e6:	c3                   	ret    

801030e7 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801030e7:	55                   	push   %ebp
801030e8:	89 e5                	mov    %esp,%ebp
801030ea:	83 ec 1c             	sub    $0x1c,%esp
801030ed:	8b 45 08             	mov    0x8(%ebp),%eax
801030f0:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801030f3:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801030fa:	00 
801030fb:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103102:	e8 b6 fd ff ff       	call   80102ebd <outb>
  outb(CMOS_PORT+1, 0x0A);
80103107:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010310e:	00 
8010310f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103116:	e8 a2 fd ff ff       	call   80102ebd <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
8010311b:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103122:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103125:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010312a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010312d:	8d 50 02             	lea    0x2(%eax),%edx
80103130:	8b 45 0c             	mov    0xc(%ebp),%eax
80103133:	c1 e8 04             	shr    $0x4,%eax
80103136:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103139:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010313d:	c1 e0 18             	shl    $0x18,%eax
80103140:	89 44 24 04          	mov    %eax,0x4(%esp)
80103144:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010314b:	e8 9b fd ff ff       	call   80102eeb <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103150:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103157:	00 
80103158:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010315f:	e8 87 fd ff ff       	call   80102eeb <lapicw>
  microdelay(200);
80103164:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010316b:	e8 72 ff ff ff       	call   801030e2 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103170:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103177:	00 
80103178:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010317f:	e8 67 fd ff ff       	call   80102eeb <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103184:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010318b:	e8 52 ff ff ff       	call   801030e2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103190:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103197:	eb 40                	jmp    801031d9 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103199:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010319d:	c1 e0 18             	shl    $0x18,%eax
801031a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801031a4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031ab:	e8 3b fd ff ff       	call   80102eeb <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801031b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801031b3:	c1 e8 0c             	shr    $0xc,%eax
801031b6:	80 cc 06             	or     $0x6,%ah
801031b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801031bd:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031c4:	e8 22 fd ff ff       	call   80102eeb <lapicw>
    microdelay(200);
801031c9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031d0:	e8 0d ff ff ff       	call   801030e2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801031d5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801031d9:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801031dd:	7e ba                	jle    80103199 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801031df:	c9                   	leave  
801031e0:	c3                   	ret    

801031e1 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801031e1:	55                   	push   %ebp
801031e2:	89 e5                	mov    %esp,%ebp
801031e4:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801031e7:	8b 45 08             	mov    0x8(%ebp),%eax
801031ea:	0f b6 c0             	movzbl %al,%eax
801031ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801031f1:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801031f8:	e8 c0 fc ff ff       	call   80102ebd <outb>
  microdelay(200);
801031fd:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103204:	e8 d9 fe ff ff       	call   801030e2 <microdelay>

  return inb(CMOS_RETURN);
80103209:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103210:	e8 8b fc ff ff       	call   80102ea0 <inb>
80103215:	0f b6 c0             	movzbl %al,%eax
}
80103218:	c9                   	leave  
80103219:	c3                   	ret    

8010321a <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
8010321a:	55                   	push   %ebp
8010321b:	89 e5                	mov    %esp,%ebp
8010321d:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103220:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103227:	e8 b5 ff ff ff       	call   801031e1 <cmos_read>
8010322c:	8b 55 08             	mov    0x8(%ebp),%edx
8010322f:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103231:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103238:	e8 a4 ff ff ff       	call   801031e1 <cmos_read>
8010323d:	8b 55 08             	mov    0x8(%ebp),%edx
80103240:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103243:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010324a:	e8 92 ff ff ff       	call   801031e1 <cmos_read>
8010324f:	8b 55 08             	mov    0x8(%ebp),%edx
80103252:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103255:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010325c:	e8 80 ff ff ff       	call   801031e1 <cmos_read>
80103261:	8b 55 08             	mov    0x8(%ebp),%edx
80103264:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103267:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010326e:	e8 6e ff ff ff       	call   801031e1 <cmos_read>
80103273:	8b 55 08             	mov    0x8(%ebp),%edx
80103276:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103279:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103280:	e8 5c ff ff ff       	call   801031e1 <cmos_read>
80103285:	8b 55 08             	mov    0x8(%ebp),%edx
80103288:	89 42 14             	mov    %eax,0x14(%edx)
}
8010328b:	c9                   	leave  
8010328c:	c3                   	ret    

8010328d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
8010328d:	55                   	push   %ebp
8010328e:	89 e5                	mov    %esp,%ebp
80103290:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103293:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
8010329a:	e8 42 ff ff ff       	call   801031e1 <cmos_read>
8010329f:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801032a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032a5:	83 e0 04             	and    $0x4,%eax
801032a8:	85 c0                	test   %eax,%eax
801032aa:	0f 94 c0             	sete   %al
801032ad:	0f b6 c0             	movzbl %al,%eax
801032b0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801032b3:	8d 45 d8             	lea    -0x28(%ebp),%eax
801032b6:	89 04 24             	mov    %eax,(%esp)
801032b9:	e8 5c ff ff ff       	call   8010321a <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801032be:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801032c5:	e8 17 ff ff ff       	call   801031e1 <cmos_read>
801032ca:	25 80 00 00 00       	and    $0x80,%eax
801032cf:	85 c0                	test   %eax,%eax
801032d1:	74 02                	je     801032d5 <cmostime+0x48>
        continue;
801032d3:	eb 36                	jmp    8010330b <cmostime+0x7e>
    fill_rtcdate(&t2);
801032d5:	8d 45 c0             	lea    -0x40(%ebp),%eax
801032d8:	89 04 24             	mov    %eax,(%esp)
801032db:	e8 3a ff ff ff       	call   8010321a <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801032e0:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801032e7:	00 
801032e8:	8d 45 c0             	lea    -0x40(%ebp),%eax
801032eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801032ef:	8d 45 d8             	lea    -0x28(%ebp),%eax
801032f2:	89 04 24             	mov    %eax,(%esp)
801032f5:	e8 ac 1f 00 00       	call   801052a6 <memcmp>
801032fa:	85 c0                	test   %eax,%eax
801032fc:	75 0d                	jne    8010330b <cmostime+0x7e>
      break;
801032fe:	90                   	nop
  }

  // convert
  if (bcd) {
801032ff:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103303:	0f 84 ac 00 00 00    	je     801033b5 <cmostime+0x128>
80103309:	eb 02                	jmp    8010330d <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
8010330b:	eb a6                	jmp    801032b3 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010330d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103310:	c1 e8 04             	shr    $0x4,%eax
80103313:	89 c2                	mov    %eax,%edx
80103315:	89 d0                	mov    %edx,%eax
80103317:	c1 e0 02             	shl    $0x2,%eax
8010331a:	01 d0                	add    %edx,%eax
8010331c:	01 c0                	add    %eax,%eax
8010331e:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103321:	83 e2 0f             	and    $0xf,%edx
80103324:	01 d0                	add    %edx,%eax
80103326:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103329:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010332c:	c1 e8 04             	shr    $0x4,%eax
8010332f:	89 c2                	mov    %eax,%edx
80103331:	89 d0                	mov    %edx,%eax
80103333:	c1 e0 02             	shl    $0x2,%eax
80103336:	01 d0                	add    %edx,%eax
80103338:	01 c0                	add    %eax,%eax
8010333a:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010333d:	83 e2 0f             	and    $0xf,%edx
80103340:	01 d0                	add    %edx,%eax
80103342:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103345:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103348:	c1 e8 04             	shr    $0x4,%eax
8010334b:	89 c2                	mov    %eax,%edx
8010334d:	89 d0                	mov    %edx,%eax
8010334f:	c1 e0 02             	shl    $0x2,%eax
80103352:	01 d0                	add    %edx,%eax
80103354:	01 c0                	add    %eax,%eax
80103356:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103359:	83 e2 0f             	and    $0xf,%edx
8010335c:	01 d0                	add    %edx,%eax
8010335e:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103361:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103364:	c1 e8 04             	shr    $0x4,%eax
80103367:	89 c2                	mov    %eax,%edx
80103369:	89 d0                	mov    %edx,%eax
8010336b:	c1 e0 02             	shl    $0x2,%eax
8010336e:	01 d0                	add    %edx,%eax
80103370:	01 c0                	add    %eax,%eax
80103372:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103375:	83 e2 0f             	and    $0xf,%edx
80103378:	01 d0                	add    %edx,%eax
8010337a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
8010337d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103380:	c1 e8 04             	shr    $0x4,%eax
80103383:	89 c2                	mov    %eax,%edx
80103385:	89 d0                	mov    %edx,%eax
80103387:	c1 e0 02             	shl    $0x2,%eax
8010338a:	01 d0                	add    %edx,%eax
8010338c:	01 c0                	add    %eax,%eax
8010338e:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103391:	83 e2 0f             	and    $0xf,%edx
80103394:	01 d0                	add    %edx,%eax
80103396:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103399:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010339c:	c1 e8 04             	shr    $0x4,%eax
8010339f:	89 c2                	mov    %eax,%edx
801033a1:	89 d0                	mov    %edx,%eax
801033a3:	c1 e0 02             	shl    $0x2,%eax
801033a6:	01 d0                	add    %edx,%eax
801033a8:	01 c0                	add    %eax,%eax
801033aa:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033ad:	83 e2 0f             	and    $0xf,%edx
801033b0:	01 d0                	add    %edx,%eax
801033b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801033b5:	8b 45 08             	mov    0x8(%ebp),%eax
801033b8:	8b 55 d8             	mov    -0x28(%ebp),%edx
801033bb:	89 10                	mov    %edx,(%eax)
801033bd:	8b 55 dc             	mov    -0x24(%ebp),%edx
801033c0:	89 50 04             	mov    %edx,0x4(%eax)
801033c3:	8b 55 e0             	mov    -0x20(%ebp),%edx
801033c6:	89 50 08             	mov    %edx,0x8(%eax)
801033c9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801033cc:	89 50 0c             	mov    %edx,0xc(%eax)
801033cf:	8b 55 e8             	mov    -0x18(%ebp),%edx
801033d2:	89 50 10             	mov    %edx,0x10(%eax)
801033d5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033d8:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801033db:	8b 45 08             	mov    0x8(%ebp),%eax
801033de:	8b 40 14             	mov    0x14(%eax),%eax
801033e1:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801033e7:	8b 45 08             	mov    0x8(%ebp),%eax
801033ea:	89 50 14             	mov    %edx,0x14(%eax)
}
801033ed:	c9                   	leave  
801033ee:	c3                   	ret    

801033ef <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
801033ef:	55                   	push   %ebp
801033f0:	89 e5                	mov    %esp,%ebp
801033f2:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801033f5:	c7 44 24 04 20 88 10 	movl   $0x80108820,0x4(%esp)
801033fc:	80 
801033fd:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103404:	e8 b1 1b 00 00       	call   80104fba <initlock>
  readsb(dev, &sb);
80103409:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010340c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103410:	8b 45 08             	mov    0x8(%ebp),%eax
80103413:	89 04 24             	mov    %eax,(%esp)
80103416:	e8 f1 de ff ff       	call   8010130c <readsb>
  log.start = sb.logstart;
8010341b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010341e:	a3 94 22 11 80       	mov    %eax,0x80112294
  log.size = sb.nlog;
80103423:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103426:	a3 98 22 11 80       	mov    %eax,0x80112298
  log.dev = dev;
8010342b:	8b 45 08             	mov    0x8(%ebp),%eax
8010342e:	a3 a4 22 11 80       	mov    %eax,0x801122a4
  recover_from_log();
80103433:	e8 9a 01 00 00       	call   801035d2 <recover_from_log>
}
80103438:	c9                   	leave  
80103439:	c3                   	ret    

8010343a <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010343a:	55                   	push   %ebp
8010343b:	89 e5                	mov    %esp,%ebp
8010343d:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103440:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103447:	e9 8c 00 00 00       	jmp    801034d8 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010344c:	8b 15 94 22 11 80    	mov    0x80112294,%edx
80103452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103455:	01 d0                	add    %edx,%eax
80103457:	83 c0 01             	add    $0x1,%eax
8010345a:	89 c2                	mov    %eax,%edx
8010345c:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103461:	89 54 24 04          	mov    %edx,0x4(%esp)
80103465:	89 04 24             	mov    %eax,(%esp)
80103468:	e8 39 cd ff ff       	call   801001a6 <bread>
8010346d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103473:	83 c0 10             	add    $0x10,%eax
80103476:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
8010347d:	89 c2                	mov    %eax,%edx
8010347f:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103484:	89 54 24 04          	mov    %edx,0x4(%esp)
80103488:	89 04 24             	mov    %eax,(%esp)
8010348b:	e8 16 cd ff ff       	call   801001a6 <bread>
80103490:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103493:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103496:	8d 50 18             	lea    0x18(%eax),%edx
80103499:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010349c:	83 c0 18             	add    $0x18,%eax
8010349f:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801034a6:	00 
801034a7:	89 54 24 04          	mov    %edx,0x4(%esp)
801034ab:	89 04 24             	mov    %eax,(%esp)
801034ae:	e8 4b 1e 00 00       	call   801052fe <memmove>
    bwrite(dbuf);  // write dst to disk
801034b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034b6:	89 04 24             	mov    %eax,(%esp)
801034b9:	e8 1f cd ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801034be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034c1:	89 04 24             	mov    %eax,(%esp)
801034c4:	e8 4e cd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801034c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034cc:	89 04 24             	mov    %eax,(%esp)
801034cf:	e8 43 cd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801034d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034d8:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801034dd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034e0:	0f 8f 66 ff ff ff    	jg     8010344c <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801034e6:	c9                   	leave  
801034e7:	c3                   	ret    

801034e8 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801034e8:	55                   	push   %ebp
801034e9:	89 e5                	mov    %esp,%ebp
801034eb:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801034ee:	a1 94 22 11 80       	mov    0x80112294,%eax
801034f3:	89 c2                	mov    %eax,%edx
801034f5:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801034fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801034fe:	89 04 24             	mov    %eax,(%esp)
80103501:	e8 a0 cc ff ff       	call   801001a6 <bread>
80103506:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010350c:	83 c0 18             	add    $0x18,%eax
8010350f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103512:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103515:	8b 00                	mov    (%eax),%eax
80103517:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  for (i = 0; i < log.lh.n; i++) {
8010351c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103523:	eb 1b                	jmp    80103540 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103525:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103528:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010352b:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010352f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103532:	83 c2 10             	add    $0x10,%edx
80103535:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010353c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103540:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103545:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103548:	7f db                	jg     80103525 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
8010354a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010354d:	89 04 24             	mov    %eax,(%esp)
80103550:	e8 c2 cc ff ff       	call   80100217 <brelse>
}
80103555:	c9                   	leave  
80103556:	c3                   	ret    

80103557 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103557:	55                   	push   %ebp
80103558:	89 e5                	mov    %esp,%ebp
8010355a:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010355d:	a1 94 22 11 80       	mov    0x80112294,%eax
80103562:	89 c2                	mov    %eax,%edx
80103564:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103569:	89 54 24 04          	mov    %edx,0x4(%esp)
8010356d:	89 04 24             	mov    %eax,(%esp)
80103570:	e8 31 cc ff ff       	call   801001a6 <bread>
80103575:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103578:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010357b:	83 c0 18             	add    $0x18,%eax
8010357e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103581:	8b 15 a8 22 11 80    	mov    0x801122a8,%edx
80103587:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010358a:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010358c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103593:	eb 1b                	jmp    801035b0 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103598:	83 c0 10             	add    $0x10,%eax
8010359b:	8b 0c 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%ecx
801035a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035a8:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801035ac:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035b0:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801035b5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035b8:	7f db                	jg     80103595 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
801035ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035bd:	89 04 24             	mov    %eax,(%esp)
801035c0:	e8 18 cc ff ff       	call   801001dd <bwrite>
  brelse(buf);
801035c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035c8:	89 04 24             	mov    %eax,(%esp)
801035cb:	e8 47 cc ff ff       	call   80100217 <brelse>
}
801035d0:	c9                   	leave  
801035d1:	c3                   	ret    

801035d2 <recover_from_log>:

static void
recover_from_log(void)
{
801035d2:	55                   	push   %ebp
801035d3:	89 e5                	mov    %esp,%ebp
801035d5:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801035d8:	e8 0b ff ff ff       	call   801034e8 <read_head>
  install_trans(); // if committed, copy from log to disk
801035dd:	e8 58 fe ff ff       	call   8010343a <install_trans>
  log.lh.n = 0;
801035e2:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
801035e9:	00 00 00 
  write_head(); // clear the log
801035ec:	e8 66 ff ff ff       	call   80103557 <write_head>
}
801035f1:	c9                   	leave  
801035f2:	c3                   	ret    

801035f3 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
801035f3:	55                   	push   %ebp
801035f4:	89 e5                	mov    %esp,%ebp
801035f6:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801035f9:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103600:	e8 d6 19 00 00       	call   80104fdb <acquire>
  while(1){
    if(log.committing){
80103605:	a1 a0 22 11 80       	mov    0x801122a0,%eax
8010360a:	85 c0                	test   %eax,%eax
8010360c:	74 16                	je     80103624 <begin_op+0x31>
      sleep(&log, &log.lock);
8010360e:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103615:	80 
80103616:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010361d:	e8 ef 16 00 00       	call   80104d11 <sleep>
80103622:	eb 4f                	jmp    80103673 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103624:	8b 0d a8 22 11 80    	mov    0x801122a8,%ecx
8010362a:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010362f:	8d 50 01             	lea    0x1(%eax),%edx
80103632:	89 d0                	mov    %edx,%eax
80103634:	c1 e0 02             	shl    $0x2,%eax
80103637:	01 d0                	add    %edx,%eax
80103639:	01 c0                	add    %eax,%eax
8010363b:	01 c8                	add    %ecx,%eax
8010363d:	83 f8 1e             	cmp    $0x1e,%eax
80103640:	7e 16                	jle    80103658 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103642:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103649:	80 
8010364a:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103651:	e8 bb 16 00 00       	call   80104d11 <sleep>
80103656:	eb 1b                	jmp    80103673 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103658:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010365d:	83 c0 01             	add    $0x1,%eax
80103660:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
80103665:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010366c:	e8 cc 19 00 00       	call   8010503d <release>
      break;
80103671:	eb 02                	jmp    80103675 <begin_op+0x82>
    }
  }
80103673:	eb 90                	jmp    80103605 <begin_op+0x12>
}
80103675:	c9                   	leave  
80103676:	c3                   	ret    

80103677 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103677:	55                   	push   %ebp
80103678:	89 e5                	mov    %esp,%ebp
8010367a:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
8010367d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103684:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010368b:	e8 4b 19 00 00       	call   80104fdb <acquire>
  log.outstanding -= 1;
80103690:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103695:	83 e8 01             	sub    $0x1,%eax
80103698:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
8010369d:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801036a2:	85 c0                	test   %eax,%eax
801036a4:	74 0c                	je     801036b2 <end_op+0x3b>
    panic("log.committing");
801036a6:	c7 04 24 24 88 10 80 	movl   $0x80108824,(%esp)
801036ad:	e8 88 ce ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801036b2:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801036b7:	85 c0                	test   %eax,%eax
801036b9:	75 13                	jne    801036ce <end_op+0x57>
    do_commit = 1;
801036bb:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801036c2:	c7 05 a0 22 11 80 01 	movl   $0x1,0x801122a0
801036c9:	00 00 00 
801036cc:	eb 0c                	jmp    801036da <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
801036ce:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801036d5:	e8 10 17 00 00       	call   80104dea <wakeup>
  }
  release(&log.lock);
801036da:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801036e1:	e8 57 19 00 00       	call   8010503d <release>

  if(do_commit){
801036e6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801036ea:	74 33                	je     8010371f <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
801036ec:	e8 de 00 00 00       	call   801037cf <commit>
    acquire(&log.lock);
801036f1:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801036f8:	e8 de 18 00 00       	call   80104fdb <acquire>
    log.committing = 0;
801036fd:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
80103704:	00 00 00 
    wakeup(&log);
80103707:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010370e:	e8 d7 16 00 00       	call   80104dea <wakeup>
    release(&log.lock);
80103713:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010371a:	e8 1e 19 00 00       	call   8010503d <release>
  }
}
8010371f:	c9                   	leave  
80103720:	c3                   	ret    

80103721 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103721:	55                   	push   %ebp
80103722:	89 e5                	mov    %esp,%ebp
80103724:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103727:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010372e:	e9 8c 00 00 00       	jmp    801037bf <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103733:	8b 15 94 22 11 80    	mov    0x80112294,%edx
80103739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010373c:	01 d0                	add    %edx,%eax
8010373e:	83 c0 01             	add    $0x1,%eax
80103741:	89 c2                	mov    %eax,%edx
80103743:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103748:	89 54 24 04          	mov    %edx,0x4(%esp)
8010374c:	89 04 24             	mov    %eax,(%esp)
8010374f:	e8 52 ca ff ff       	call   801001a6 <bread>
80103754:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010375a:	83 c0 10             	add    $0x10,%eax
8010375d:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103764:	89 c2                	mov    %eax,%edx
80103766:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010376b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010376f:	89 04 24             	mov    %eax,(%esp)
80103772:	e8 2f ca ff ff       	call   801001a6 <bread>
80103777:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
8010377a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010377d:	8d 50 18             	lea    0x18(%eax),%edx
80103780:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103783:	83 c0 18             	add    $0x18,%eax
80103786:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010378d:	00 
8010378e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103792:	89 04 24             	mov    %eax,(%esp)
80103795:	e8 64 1b 00 00       	call   801052fe <memmove>
    bwrite(to);  // write the log
8010379a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010379d:	89 04 24             	mov    %eax,(%esp)
801037a0:	e8 38 ca ff ff       	call   801001dd <bwrite>
    brelse(from); 
801037a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037a8:	89 04 24             	mov    %eax,(%esp)
801037ab:	e8 67 ca ff ff       	call   80100217 <brelse>
    brelse(to);
801037b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037b3:	89 04 24             	mov    %eax,(%esp)
801037b6:	e8 5c ca ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801037bb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037bf:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801037c4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037c7:	0f 8f 66 ff ff ff    	jg     80103733 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
801037cd:	c9                   	leave  
801037ce:	c3                   	ret    

801037cf <commit>:

static void
commit()
{
801037cf:	55                   	push   %ebp
801037d0:	89 e5                	mov    %esp,%ebp
801037d2:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
801037d5:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801037da:	85 c0                	test   %eax,%eax
801037dc:	7e 1e                	jle    801037fc <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
801037de:	e8 3e ff ff ff       	call   80103721 <write_log>
    write_head();    // Write header to disk -- the real commit
801037e3:	e8 6f fd ff ff       	call   80103557 <write_head>
    install_trans(); // Now install writes to home locations
801037e8:	e8 4d fc ff ff       	call   8010343a <install_trans>
    log.lh.n = 0; 
801037ed:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
801037f4:	00 00 00 
    write_head();    // Erase the transaction from the log
801037f7:	e8 5b fd ff ff       	call   80103557 <write_head>
  }
}
801037fc:	c9                   	leave  
801037fd:	c3                   	ret    

801037fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801037fe:	55                   	push   %ebp
801037ff:	89 e5                	mov    %esp,%ebp
80103801:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103804:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103809:	83 f8 1d             	cmp    $0x1d,%eax
8010380c:	7f 12                	jg     80103820 <log_write+0x22>
8010380e:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103813:	8b 15 98 22 11 80    	mov    0x80112298,%edx
80103819:	83 ea 01             	sub    $0x1,%edx
8010381c:	39 d0                	cmp    %edx,%eax
8010381e:	7c 0c                	jl     8010382c <log_write+0x2e>
    panic("too big a transaction");
80103820:	c7 04 24 33 88 10 80 	movl   $0x80108833,(%esp)
80103827:	e8 0e cd ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
8010382c:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103831:	85 c0                	test   %eax,%eax
80103833:	7f 0c                	jg     80103841 <log_write+0x43>
    panic("log_write outside of trans");
80103835:	c7 04 24 49 88 10 80 	movl   $0x80108849,(%esp)
8010383c:	e8 f9 cc ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103841:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103848:	e8 8e 17 00 00       	call   80104fdb <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010384d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103854:	eb 1f                	jmp    80103875 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103856:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103859:	83 c0 10             	add    $0x10,%eax
8010385c:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103863:	89 c2                	mov    %eax,%edx
80103865:	8b 45 08             	mov    0x8(%ebp),%eax
80103868:	8b 40 08             	mov    0x8(%eax),%eax
8010386b:	39 c2                	cmp    %eax,%edx
8010386d:	75 02                	jne    80103871 <log_write+0x73>
      break;
8010386f:	eb 0e                	jmp    8010387f <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103871:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103875:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010387a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010387d:	7f d7                	jg     80103856 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
8010387f:	8b 45 08             	mov    0x8(%ebp),%eax
80103882:	8b 40 08             	mov    0x8(%eax),%eax
80103885:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103888:	83 c2 10             	add    $0x10,%edx
8010388b:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
  if (i == log.lh.n)
80103892:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103897:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010389a:	75 0d                	jne    801038a9 <log_write+0xab>
    log.lh.n++;
8010389c:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801038a1:	83 c0 01             	add    $0x1,%eax
801038a4:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  b->flags |= B_DIRTY; // prevent eviction
801038a9:	8b 45 08             	mov    0x8(%ebp),%eax
801038ac:	8b 00                	mov    (%eax),%eax
801038ae:	83 c8 04             	or     $0x4,%eax
801038b1:	89 c2                	mov    %eax,%edx
801038b3:	8b 45 08             	mov    0x8(%ebp),%eax
801038b6:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801038b8:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801038bf:	e8 79 17 00 00       	call   8010503d <release>
}
801038c4:	c9                   	leave  
801038c5:	c3                   	ret    

801038c6 <v2p>:
801038c6:	55                   	push   %ebp
801038c7:	89 e5                	mov    %esp,%ebp
801038c9:	8b 45 08             	mov    0x8(%ebp),%eax
801038cc:	05 00 00 00 80       	add    $0x80000000,%eax
801038d1:	5d                   	pop    %ebp
801038d2:	c3                   	ret    

801038d3 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801038d3:	55                   	push   %ebp
801038d4:	89 e5                	mov    %esp,%ebp
801038d6:	8b 45 08             	mov    0x8(%ebp),%eax
801038d9:	05 00 00 00 80       	add    $0x80000000,%eax
801038de:	5d                   	pop    %ebp
801038df:	c3                   	ret    

801038e0 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801038e0:	55                   	push   %ebp
801038e1:	89 e5                	mov    %esp,%ebp
801038e3:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801038e6:	8b 55 08             	mov    0x8(%ebp),%edx
801038e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801038ec:	8b 4d 08             	mov    0x8(%ebp),%ecx
801038ef:	f0 87 02             	lock xchg %eax,(%edx)
801038f2:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801038f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801038f8:	c9                   	leave  
801038f9:	c3                   	ret    

801038fa <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801038fa:	55                   	push   %ebp
801038fb:	89 e5                	mov    %esp,%ebp
801038fd:	83 e4 f0             	and    $0xfffffff0,%esp
80103900:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103903:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010390a:	80 
8010390b:	c7 04 24 3c 51 11 80 	movl   $0x8011513c,(%esp)
80103912:	e8 8a f2 ff ff       	call   80102ba1 <kinit1>
  kvmalloc();      // kernel page table
80103917:	e8 d8 44 00 00       	call   80107df4 <kvmalloc>
  mpinit();        // collect info about this machine
8010391c:	e8 41 04 00 00       	call   80103d62 <mpinit>
  lapicinit();
80103921:	e8 e6 f5 ff ff       	call   80102f0c <lapicinit>
  seginit();       // set up segments
80103926:	e8 5c 3e 00 00       	call   80107787 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010392b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103931:	0f b6 00             	movzbl (%eax),%eax
80103934:	0f b6 c0             	movzbl %al,%eax
80103937:	89 44 24 04          	mov    %eax,0x4(%esp)
8010393b:	c7 04 24 64 88 10 80 	movl   $0x80108864,(%esp)
80103942:	e8 59 ca ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103947:	e8 74 06 00 00       	call   80103fc0 <picinit>
  ioapicinit();    // another interrupt controller
8010394c:	e8 46 f1 ff ff       	call   80102a97 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103951:	e8 5a d1 ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103956:	e8 7b 31 00 00       	call   80106ad6 <uartinit>
  pinit();         // process table
8010395b:	e8 6a 0b 00 00       	call   801044ca <pinit>
  tvinit();        // trap vectors
80103960:	e8 23 2d 00 00       	call   80106688 <tvinit>
  binit();         // buffer cache
80103965:	e8 ca c6 ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010396a:	e8 b6 d5 ff ff       	call   80100f25 <fileinit>
  ideinit();       // disk
8010396f:	e8 55 ed ff ff       	call   801026c9 <ideinit>
  if(!ismp)
80103974:	a1 44 23 11 80       	mov    0x80112344,%eax
80103979:	85 c0                	test   %eax,%eax
8010397b:	75 05                	jne    80103982 <main+0x88>
    timerinit();   // uniprocessor timer
8010397d:	e8 51 2c 00 00       	call   801065d3 <timerinit>
  startothers();   // start other processors
80103982:	e8 7f 00 00 00       	call   80103a06 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103987:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
8010398e:	8e 
8010398f:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103996:	e8 3e f2 ff ff       	call   80102bd9 <kinit2>
  userinit();      // first user process
8010399b:	e8 45 0c 00 00       	call   801045e5 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801039a0:	e8 1a 00 00 00       	call   801039bf <mpmain>

801039a5 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801039a5:	55                   	push   %ebp
801039a6:	89 e5                	mov    %esp,%ebp
801039a8:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801039ab:	e8 5b 44 00 00       	call   80107e0b <switchkvm>
  seginit();
801039b0:	e8 d2 3d 00 00       	call   80107787 <seginit>
  lapicinit();
801039b5:	e8 52 f5 ff ff       	call   80102f0c <lapicinit>
  mpmain();
801039ba:	e8 00 00 00 00       	call   801039bf <mpmain>

801039bf <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801039bf:	55                   	push   %ebp
801039c0:	89 e5                	mov    %esp,%ebp
801039c2:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801039c5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801039cb:	0f b6 00             	movzbl (%eax),%eax
801039ce:	0f b6 c0             	movzbl %al,%eax
801039d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801039d5:	c7 04 24 7b 88 10 80 	movl   $0x8010887b,(%esp)
801039dc:	e8 bf c9 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
801039e1:	e8 16 2e 00 00       	call   801067fc <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801039e6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801039ec:	05 a8 00 00 00       	add    $0xa8,%eax
801039f1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801039f8:	00 
801039f9:	89 04 24             	mov    %eax,(%esp)
801039fc:	e8 df fe ff ff       	call   801038e0 <xchg>
  scheduler();     // start running processes
80103a01:	e8 50 11 00 00       	call   80104b56 <scheduler>

80103a06 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103a06:	55                   	push   %ebp
80103a07:	89 e5                	mov    %esp,%ebp
80103a09:	53                   	push   %ebx
80103a0a:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103a0d:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103a14:	e8 ba fe ff ff       	call   801038d3 <p2v>
80103a19:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103a1c:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103a21:	89 44 24 08          	mov    %eax,0x8(%esp)
80103a25:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103a2c:	80 
80103a2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a30:	89 04 24             	mov    %eax,(%esp)
80103a33:	e8 c6 18 00 00       	call   801052fe <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103a38:	c7 45 f4 60 23 11 80 	movl   $0x80112360,-0xc(%ebp)
80103a3f:	e9 85 00 00 00       	jmp    80103ac9 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103a44:	e8 1c f6 ff ff       	call   80103065 <cpunum>
80103a49:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a4f:	05 60 23 11 80       	add    $0x80112360,%eax
80103a54:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a57:	75 02                	jne    80103a5b <startothers+0x55>
      continue;
80103a59:	eb 67                	jmp    80103ac2 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103a5b:	e8 6f f2 ff ff       	call   80102ccf <kalloc>
80103a60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a66:	83 e8 04             	sub    $0x4,%eax
80103a69:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103a6c:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103a72:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103a74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a77:	83 e8 08             	sub    $0x8,%eax
80103a7a:	c7 00 a5 39 10 80    	movl   $0x801039a5,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103a80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a83:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103a86:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103a8d:	e8 34 fe ff ff       	call   801038c6 <v2p>
80103a92:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103a94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a97:	89 04 24             	mov    %eax,(%esp)
80103a9a:	e8 27 fe ff ff       	call   801038c6 <v2p>
80103a9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103aa2:	0f b6 12             	movzbl (%edx),%edx
80103aa5:	0f b6 d2             	movzbl %dl,%edx
80103aa8:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aac:	89 14 24             	mov    %edx,(%esp)
80103aaf:	e8 33 f6 ff ff       	call   801030e7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103ab4:	90                   	nop
80103ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ab8:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103abe:	85 c0                	test   %eax,%eax
80103ac0:	74 f3                	je     80103ab5 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103ac2:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103ac9:	a1 40 29 11 80       	mov    0x80112940,%eax
80103ace:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103ad4:	05 60 23 11 80       	add    $0x80112360,%eax
80103ad9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103adc:	0f 87 62 ff ff ff    	ja     80103a44 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103ae2:	83 c4 24             	add    $0x24,%esp
80103ae5:	5b                   	pop    %ebx
80103ae6:	5d                   	pop    %ebp
80103ae7:	c3                   	ret    

80103ae8 <p2v>:
80103ae8:	55                   	push   %ebp
80103ae9:	89 e5                	mov    %esp,%ebp
80103aeb:	8b 45 08             	mov    0x8(%ebp),%eax
80103aee:	05 00 00 00 80       	add    $0x80000000,%eax
80103af3:	5d                   	pop    %ebp
80103af4:	c3                   	ret    

80103af5 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103af5:	55                   	push   %ebp
80103af6:	89 e5                	mov    %esp,%ebp
80103af8:	83 ec 14             	sub    $0x14,%esp
80103afb:	8b 45 08             	mov    0x8(%ebp),%eax
80103afe:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103b02:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103b06:	89 c2                	mov    %eax,%edx
80103b08:	ec                   	in     (%dx),%al
80103b09:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103b0c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103b10:	c9                   	leave  
80103b11:	c3                   	ret    

80103b12 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b12:	55                   	push   %ebp
80103b13:	89 e5                	mov    %esp,%ebp
80103b15:	83 ec 08             	sub    $0x8,%esp
80103b18:	8b 55 08             	mov    0x8(%ebp),%edx
80103b1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b1e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b22:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b25:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b29:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b2d:	ee                   	out    %al,(%dx)
}
80103b2e:	c9                   	leave  
80103b2f:	c3                   	ret    

80103b30 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103b30:	55                   	push   %ebp
80103b31:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103b33:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103b38:	89 c2                	mov    %eax,%edx
80103b3a:	b8 60 23 11 80       	mov    $0x80112360,%eax
80103b3f:	29 c2                	sub    %eax,%edx
80103b41:	89 d0                	mov    %edx,%eax
80103b43:	c1 f8 02             	sar    $0x2,%eax
80103b46:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103b4c:	5d                   	pop    %ebp
80103b4d:	c3                   	ret    

80103b4e <sum>:

static uchar
sum(uchar *addr, int len)
{
80103b4e:	55                   	push   %ebp
80103b4f:	89 e5                	mov    %esp,%ebp
80103b51:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103b54:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103b5b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103b62:	eb 15                	jmp    80103b79 <sum+0x2b>
    sum += addr[i];
80103b64:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103b67:	8b 45 08             	mov    0x8(%ebp),%eax
80103b6a:	01 d0                	add    %edx,%eax
80103b6c:	0f b6 00             	movzbl (%eax),%eax
80103b6f:	0f b6 c0             	movzbl %al,%eax
80103b72:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103b75:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103b79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103b7c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103b7f:	7c e3                	jl     80103b64 <sum+0x16>
    sum += addr[i];
  return sum;
80103b81:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103b84:	c9                   	leave  
80103b85:	c3                   	ret    

80103b86 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103b86:	55                   	push   %ebp
80103b87:	89 e5                	mov    %esp,%ebp
80103b89:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103b8c:	8b 45 08             	mov    0x8(%ebp),%eax
80103b8f:	89 04 24             	mov    %eax,(%esp)
80103b92:	e8 51 ff ff ff       	call   80103ae8 <p2v>
80103b97:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103b9a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ba0:	01 d0                	add    %edx,%eax
80103ba2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103ba5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ba8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bab:	eb 3f                	jmp    80103bec <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103bad:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103bb4:	00 
80103bb5:	c7 44 24 04 8c 88 10 	movl   $0x8010888c,0x4(%esp)
80103bbc:	80 
80103bbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bc0:	89 04 24             	mov    %eax,(%esp)
80103bc3:	e8 de 16 00 00       	call   801052a6 <memcmp>
80103bc8:	85 c0                	test   %eax,%eax
80103bca:	75 1c                	jne    80103be8 <mpsearch1+0x62>
80103bcc:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103bd3:	00 
80103bd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd7:	89 04 24             	mov    %eax,(%esp)
80103bda:	e8 6f ff ff ff       	call   80103b4e <sum>
80103bdf:	84 c0                	test   %al,%al
80103be1:	75 05                	jne    80103be8 <mpsearch1+0x62>
      return (struct mp*)p;
80103be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be6:	eb 11                	jmp    80103bf9 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103be8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103bec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bef:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103bf2:	72 b9                	jb     80103bad <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103bf4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103bf9:	c9                   	leave  
80103bfa:	c3                   	ret    

80103bfb <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103bfb:	55                   	push   %ebp
80103bfc:	89 e5                	mov    %esp,%ebp
80103bfe:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103c01:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c0b:	83 c0 0f             	add    $0xf,%eax
80103c0e:	0f b6 00             	movzbl (%eax),%eax
80103c11:	0f b6 c0             	movzbl %al,%eax
80103c14:	c1 e0 08             	shl    $0x8,%eax
80103c17:	89 c2                	mov    %eax,%edx
80103c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c1c:	83 c0 0e             	add    $0xe,%eax
80103c1f:	0f b6 00             	movzbl (%eax),%eax
80103c22:	0f b6 c0             	movzbl %al,%eax
80103c25:	09 d0                	or     %edx,%eax
80103c27:	c1 e0 04             	shl    $0x4,%eax
80103c2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103c2d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c31:	74 21                	je     80103c54 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103c33:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c3a:	00 
80103c3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c3e:	89 04 24             	mov    %eax,(%esp)
80103c41:	e8 40 ff ff ff       	call   80103b86 <mpsearch1>
80103c46:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c49:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c4d:	74 50                	je     80103c9f <mpsearch+0xa4>
      return mp;
80103c4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c52:	eb 5f                	jmp    80103cb3 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103c54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c57:	83 c0 14             	add    $0x14,%eax
80103c5a:	0f b6 00             	movzbl (%eax),%eax
80103c5d:	0f b6 c0             	movzbl %al,%eax
80103c60:	c1 e0 08             	shl    $0x8,%eax
80103c63:	89 c2                	mov    %eax,%edx
80103c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c68:	83 c0 13             	add    $0x13,%eax
80103c6b:	0f b6 00             	movzbl (%eax),%eax
80103c6e:	0f b6 c0             	movzbl %al,%eax
80103c71:	09 d0                	or     %edx,%eax
80103c73:	c1 e0 0a             	shl    $0xa,%eax
80103c76:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103c79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c7c:	2d 00 04 00 00       	sub    $0x400,%eax
80103c81:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c88:	00 
80103c89:	89 04 24             	mov    %eax,(%esp)
80103c8c:	e8 f5 fe ff ff       	call   80103b86 <mpsearch1>
80103c91:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c94:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c98:	74 05                	je     80103c9f <mpsearch+0xa4>
      return mp;
80103c9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c9d:	eb 14                	jmp    80103cb3 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103c9f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ca6:	00 
80103ca7:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103cae:	e8 d3 fe ff ff       	call   80103b86 <mpsearch1>
}
80103cb3:	c9                   	leave  
80103cb4:	c3                   	ret    

80103cb5 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103cb5:	55                   	push   %ebp
80103cb6:	89 e5                	mov    %esp,%ebp
80103cb8:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103cbb:	e8 3b ff ff ff       	call   80103bfb <mpsearch>
80103cc0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cc3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cc7:	74 0a                	je     80103cd3 <mpconfig+0x1e>
80103cc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ccc:	8b 40 04             	mov    0x4(%eax),%eax
80103ccf:	85 c0                	test   %eax,%eax
80103cd1:	75 0a                	jne    80103cdd <mpconfig+0x28>
    return 0;
80103cd3:	b8 00 00 00 00       	mov    $0x0,%eax
80103cd8:	e9 83 00 00 00       	jmp    80103d60 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103cdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce0:	8b 40 04             	mov    0x4(%eax),%eax
80103ce3:	89 04 24             	mov    %eax,(%esp)
80103ce6:	e8 fd fd ff ff       	call   80103ae8 <p2v>
80103ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103cee:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103cf5:	00 
80103cf6:	c7 44 24 04 91 88 10 	movl   $0x80108891,0x4(%esp)
80103cfd:	80 
80103cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d01:	89 04 24             	mov    %eax,(%esp)
80103d04:	e8 9d 15 00 00       	call   801052a6 <memcmp>
80103d09:	85 c0                	test   %eax,%eax
80103d0b:	74 07                	je     80103d14 <mpconfig+0x5f>
    return 0;
80103d0d:	b8 00 00 00 00       	mov    $0x0,%eax
80103d12:	eb 4c                	jmp    80103d60 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103d14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d17:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d1b:	3c 01                	cmp    $0x1,%al
80103d1d:	74 12                	je     80103d31 <mpconfig+0x7c>
80103d1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d22:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d26:	3c 04                	cmp    $0x4,%al
80103d28:	74 07                	je     80103d31 <mpconfig+0x7c>
    return 0;
80103d2a:	b8 00 00 00 00       	mov    $0x0,%eax
80103d2f:	eb 2f                	jmp    80103d60 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103d31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d34:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103d38:	0f b7 c0             	movzwl %ax,%eax
80103d3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d42:	89 04 24             	mov    %eax,(%esp)
80103d45:	e8 04 fe ff ff       	call   80103b4e <sum>
80103d4a:	84 c0                	test   %al,%al
80103d4c:	74 07                	je     80103d55 <mpconfig+0xa0>
    return 0;
80103d4e:	b8 00 00 00 00       	mov    $0x0,%eax
80103d53:	eb 0b                	jmp    80103d60 <mpconfig+0xab>
  *pmp = mp;
80103d55:	8b 45 08             	mov    0x8(%ebp),%eax
80103d58:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d5b:	89 10                	mov    %edx,(%eax)
  return conf;
80103d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103d60:	c9                   	leave  
80103d61:	c3                   	ret    

80103d62 <mpinit>:

void
mpinit(void)
{
80103d62:	55                   	push   %ebp
80103d63:	89 e5                	mov    %esp,%ebp
80103d65:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103d68:	c7 05 44 b6 10 80 60 	movl   $0x80112360,0x8010b644
80103d6f:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103d72:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103d75:	89 04 24             	mov    %eax,(%esp)
80103d78:	e8 38 ff ff ff       	call   80103cb5 <mpconfig>
80103d7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103d80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103d84:	75 05                	jne    80103d8b <mpinit+0x29>
    return;
80103d86:	e9 9c 01 00 00       	jmp    80103f27 <mpinit+0x1c5>
  ismp = 1;
80103d8b:	c7 05 44 23 11 80 01 	movl   $0x1,0x80112344
80103d92:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d98:	8b 40 24             	mov    0x24(%eax),%eax
80103d9b:	a3 5c 22 11 80       	mov    %eax,0x8011225c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103da0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103da3:	83 c0 2c             	add    $0x2c,%eax
80103da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103da9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dac:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103db0:	0f b7 d0             	movzwl %ax,%edx
80103db3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103db6:	01 d0                	add    %edx,%eax
80103db8:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103dbb:	e9 f4 00 00 00       	jmp    80103eb4 <mpinit+0x152>
    switch(*p){
80103dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dc3:	0f b6 00             	movzbl (%eax),%eax
80103dc6:	0f b6 c0             	movzbl %al,%eax
80103dc9:	83 f8 04             	cmp    $0x4,%eax
80103dcc:	0f 87 bf 00 00 00    	ja     80103e91 <mpinit+0x12f>
80103dd2:	8b 04 85 d4 88 10 80 	mov    -0x7fef772c(,%eax,4),%eax
80103dd9:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103ddb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dde:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103de1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103de4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103de8:	0f b6 d0             	movzbl %al,%edx
80103deb:	a1 40 29 11 80       	mov    0x80112940,%eax
80103df0:	39 c2                	cmp    %eax,%edx
80103df2:	74 2d                	je     80103e21 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103df4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103df7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103dfb:	0f b6 d0             	movzbl %al,%edx
80103dfe:	a1 40 29 11 80       	mov    0x80112940,%eax
80103e03:	89 54 24 08          	mov    %edx,0x8(%esp)
80103e07:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e0b:	c7 04 24 96 88 10 80 	movl   $0x80108896,(%esp)
80103e12:	e8 89 c5 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103e17:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103e1e:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103e21:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e24:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103e28:	0f b6 c0             	movzbl %al,%eax
80103e2b:	83 e0 02             	and    $0x2,%eax
80103e2e:	85 c0                	test   %eax,%eax
80103e30:	74 15                	je     80103e47 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103e32:	a1 40 29 11 80       	mov    0x80112940,%eax
80103e37:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e3d:	05 60 23 11 80       	add    $0x80112360,%eax
80103e42:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103e47:	8b 15 40 29 11 80    	mov    0x80112940,%edx
80103e4d:	a1 40 29 11 80       	mov    0x80112940,%eax
80103e52:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103e58:	81 c2 60 23 11 80    	add    $0x80112360,%edx
80103e5e:	88 02                	mov    %al,(%edx)
      ncpu++;
80103e60:	a1 40 29 11 80       	mov    0x80112940,%eax
80103e65:	83 c0 01             	add    $0x1,%eax
80103e68:	a3 40 29 11 80       	mov    %eax,0x80112940
      p += sizeof(struct mpproc);
80103e6d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103e71:	eb 41                	jmp    80103eb4 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103e79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103e7c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e80:	a2 40 23 11 80       	mov    %al,0x80112340
      p += sizeof(struct mpioapic);
80103e85:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103e89:	eb 29                	jmp    80103eb4 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103e8b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103e8f:	eb 23                	jmp    80103eb4 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e94:	0f b6 00             	movzbl (%eax),%eax
80103e97:	0f b6 c0             	movzbl %al,%eax
80103e9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e9e:	c7 04 24 b4 88 10 80 	movl   $0x801088b4,(%esp)
80103ea5:	e8 f6 c4 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103eaa:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103eb1:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eb7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103eba:	0f 82 00 ff ff ff    	jb     80103dc0 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103ec0:	a1 44 23 11 80       	mov    0x80112344,%eax
80103ec5:	85 c0                	test   %eax,%eax
80103ec7:	75 1d                	jne    80103ee6 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103ec9:	c7 05 40 29 11 80 01 	movl   $0x1,0x80112940
80103ed0:	00 00 00 
    lapic = 0;
80103ed3:	c7 05 5c 22 11 80 00 	movl   $0x0,0x8011225c
80103eda:	00 00 00 
    ioapicid = 0;
80103edd:	c6 05 40 23 11 80 00 	movb   $0x0,0x80112340
    return;
80103ee4:	eb 41                	jmp    80103f27 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103ee6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103ee9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103eed:	84 c0                	test   %al,%al
80103eef:	74 36                	je     80103f27 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103ef1:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103ef8:	00 
80103ef9:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103f00:	e8 0d fc ff ff       	call   80103b12 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103f05:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f0c:	e8 e4 fb ff ff       	call   80103af5 <inb>
80103f11:	83 c8 01             	or     $0x1,%eax
80103f14:	0f b6 c0             	movzbl %al,%eax
80103f17:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f1b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f22:	e8 eb fb ff ff       	call   80103b12 <outb>
  }
}
80103f27:	c9                   	leave  
80103f28:	c3                   	ret    

80103f29 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f29:	55                   	push   %ebp
80103f2a:	89 e5                	mov    %esp,%ebp
80103f2c:	83 ec 08             	sub    $0x8,%esp
80103f2f:	8b 55 08             	mov    0x8(%ebp),%edx
80103f32:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f35:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f39:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f3c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f40:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f44:	ee                   	out    %al,(%dx)
}
80103f45:	c9                   	leave  
80103f46:	c3                   	ret    

80103f47 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103f47:	55                   	push   %ebp
80103f48:	89 e5                	mov    %esp,%ebp
80103f4a:	83 ec 0c             	sub    $0xc,%esp
80103f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f50:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103f54:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f58:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103f5e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f62:	0f b6 c0             	movzbl %al,%eax
80103f65:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f69:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f70:	e8 b4 ff ff ff       	call   80103f29 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103f75:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f79:	66 c1 e8 08          	shr    $0x8,%ax
80103f7d:	0f b6 c0             	movzbl %al,%eax
80103f80:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f84:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f8b:	e8 99 ff ff ff       	call   80103f29 <outb>
}
80103f90:	c9                   	leave  
80103f91:	c3                   	ret    

80103f92 <picenable>:

void
picenable(int irq)
{
80103f92:	55                   	push   %ebp
80103f93:	89 e5                	mov    %esp,%ebp
80103f95:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103f98:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9b:	ba 01 00 00 00       	mov    $0x1,%edx
80103fa0:	89 c1                	mov    %eax,%ecx
80103fa2:	d3 e2                	shl    %cl,%edx
80103fa4:	89 d0                	mov    %edx,%eax
80103fa6:	f7 d0                	not    %eax
80103fa8:	89 c2                	mov    %eax,%edx
80103faa:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103fb1:	21 d0                	and    %edx,%eax
80103fb3:	0f b7 c0             	movzwl %ax,%eax
80103fb6:	89 04 24             	mov    %eax,(%esp)
80103fb9:	e8 89 ff ff ff       	call   80103f47 <picsetmask>
}
80103fbe:	c9                   	leave  
80103fbf:	c3                   	ret    

80103fc0 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103fc0:	55                   	push   %ebp
80103fc1:	89 e5                	mov    %esp,%ebp
80103fc3:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103fc6:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103fcd:	00 
80103fce:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103fd5:	e8 4f ff ff ff       	call   80103f29 <outb>
  outb(IO_PIC2+1, 0xFF);
80103fda:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103fe1:	00 
80103fe2:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fe9:	e8 3b ff ff ff       	call   80103f29 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103fee:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103ff5:	00 
80103ff6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ffd:	e8 27 ff ff ff       	call   80103f29 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104002:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104009:	00 
8010400a:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104011:	e8 13 ff ff ff       	call   80103f29 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104016:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
8010401d:	00 
8010401e:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104025:	e8 ff fe ff ff       	call   80103f29 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
8010402a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104031:	00 
80104032:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104039:	e8 eb fe ff ff       	call   80103f29 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
8010403e:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104045:	00 
80104046:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010404d:	e8 d7 fe ff ff       	call   80103f29 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104052:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104059:	00 
8010405a:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104061:	e8 c3 fe ff ff       	call   80103f29 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104066:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010406d:	00 
8010406e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104075:	e8 af fe ff ff       	call   80103f29 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
8010407a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104081:	00 
80104082:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104089:	e8 9b fe ff ff       	call   80103f29 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
8010408e:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104095:	00 
80104096:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010409d:	e8 87 fe ff ff       	call   80103f29 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801040a2:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040a9:	00 
801040aa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040b1:	e8 73 fe ff ff       	call   80103f29 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801040b6:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040bd:	00 
801040be:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040c5:	e8 5f fe ff ff       	call   80103f29 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
801040ca:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040d1:	00 
801040d2:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040d9:	e8 4b fe ff ff       	call   80103f29 <outb>

  if(irqmask != 0xFFFF)
801040de:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
801040e5:	66 83 f8 ff          	cmp    $0xffff,%ax
801040e9:	74 12                	je     801040fd <picinit+0x13d>
    picsetmask(irqmask);
801040eb:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
801040f2:	0f b7 c0             	movzwl %ax,%eax
801040f5:	89 04 24             	mov    %eax,(%esp)
801040f8:	e8 4a fe ff ff       	call   80103f47 <picsetmask>
}
801040fd:	c9                   	leave  
801040fe:	c3                   	ret    

801040ff <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801040ff:	55                   	push   %ebp
80104100:	89 e5                	mov    %esp,%ebp
80104102:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104105:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
8010410c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010410f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104115:	8b 45 0c             	mov    0xc(%ebp),%eax
80104118:	8b 10                	mov    (%eax),%edx
8010411a:	8b 45 08             	mov    0x8(%ebp),%eax
8010411d:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
8010411f:	e8 1d ce ff ff       	call   80100f41 <filealloc>
80104124:	8b 55 08             	mov    0x8(%ebp),%edx
80104127:	89 02                	mov    %eax,(%edx)
80104129:	8b 45 08             	mov    0x8(%ebp),%eax
8010412c:	8b 00                	mov    (%eax),%eax
8010412e:	85 c0                	test   %eax,%eax
80104130:	0f 84 c8 00 00 00    	je     801041fe <pipealloc+0xff>
80104136:	e8 06 ce ff ff       	call   80100f41 <filealloc>
8010413b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010413e:	89 02                	mov    %eax,(%edx)
80104140:	8b 45 0c             	mov    0xc(%ebp),%eax
80104143:	8b 00                	mov    (%eax),%eax
80104145:	85 c0                	test   %eax,%eax
80104147:	0f 84 b1 00 00 00    	je     801041fe <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010414d:	e8 7d eb ff ff       	call   80102ccf <kalloc>
80104152:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104155:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104159:	75 05                	jne    80104160 <pipealloc+0x61>
    goto bad;
8010415b:	e9 9e 00 00 00       	jmp    801041fe <pipealloc+0xff>
  p->readopen = 1;
80104160:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104163:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010416a:	00 00 00 
  p->writeopen = 1;
8010416d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104170:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104177:	00 00 00 
  p->nwrite = 0;
8010417a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104184:	00 00 00 
  p->nread = 0;
80104187:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010418a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104191:	00 00 00 
  initlock(&p->lock, "pipe");
80104194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104197:	c7 44 24 04 e8 88 10 	movl   $0x801088e8,0x4(%esp)
8010419e:	80 
8010419f:	89 04 24             	mov    %eax,(%esp)
801041a2:	e8 13 0e 00 00       	call   80104fba <initlock>
  (*f0)->type = FD_PIPE;
801041a7:	8b 45 08             	mov    0x8(%ebp),%eax
801041aa:	8b 00                	mov    (%eax),%eax
801041ac:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801041b2:	8b 45 08             	mov    0x8(%ebp),%eax
801041b5:	8b 00                	mov    (%eax),%eax
801041b7:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801041bb:	8b 45 08             	mov    0x8(%ebp),%eax
801041be:	8b 00                	mov    (%eax),%eax
801041c0:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801041c4:	8b 45 08             	mov    0x8(%ebp),%eax
801041c7:	8b 00                	mov    (%eax),%eax
801041c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041cc:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
801041cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801041d2:	8b 00                	mov    (%eax),%eax
801041d4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801041da:	8b 45 0c             	mov    0xc(%ebp),%eax
801041dd:	8b 00                	mov    (%eax),%eax
801041df:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801041e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e6:	8b 00                	mov    (%eax),%eax
801041e8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801041ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801041ef:	8b 00                	mov    (%eax),%eax
801041f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041f4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801041f7:	b8 00 00 00 00       	mov    $0x0,%eax
801041fc:	eb 42                	jmp    80104240 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801041fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104202:	74 0b                	je     8010420f <pipealloc+0x110>
    kfree((char*)p);
80104204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104207:	89 04 24             	mov    %eax,(%esp)
8010420a:	e8 27 ea ff ff       	call   80102c36 <kfree>
  if(*f0)
8010420f:	8b 45 08             	mov    0x8(%ebp),%eax
80104212:	8b 00                	mov    (%eax),%eax
80104214:	85 c0                	test   %eax,%eax
80104216:	74 0d                	je     80104225 <pipealloc+0x126>
    fileclose(*f0);
80104218:	8b 45 08             	mov    0x8(%ebp),%eax
8010421b:	8b 00                	mov    (%eax),%eax
8010421d:	89 04 24             	mov    %eax,(%esp)
80104220:	e8 c4 cd ff ff       	call   80100fe9 <fileclose>
  if(*f1)
80104225:	8b 45 0c             	mov    0xc(%ebp),%eax
80104228:	8b 00                	mov    (%eax),%eax
8010422a:	85 c0                	test   %eax,%eax
8010422c:	74 0d                	je     8010423b <pipealloc+0x13c>
    fileclose(*f1);
8010422e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104231:	8b 00                	mov    (%eax),%eax
80104233:	89 04 24             	mov    %eax,(%esp)
80104236:	e8 ae cd ff ff       	call   80100fe9 <fileclose>
  return -1;
8010423b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104240:	c9                   	leave  
80104241:	c3                   	ret    

80104242 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104242:	55                   	push   %ebp
80104243:	89 e5                	mov    %esp,%ebp
80104245:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104248:	8b 45 08             	mov    0x8(%ebp),%eax
8010424b:	89 04 24             	mov    %eax,(%esp)
8010424e:	e8 88 0d 00 00       	call   80104fdb <acquire>
  if(writable){
80104253:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104257:	74 1f                	je     80104278 <pipeclose+0x36>
    p->writeopen = 0;
80104259:	8b 45 08             	mov    0x8(%ebp),%eax
8010425c:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104263:	00 00 00 
    wakeup(&p->nread);
80104266:	8b 45 08             	mov    0x8(%ebp),%eax
80104269:	05 34 02 00 00       	add    $0x234,%eax
8010426e:	89 04 24             	mov    %eax,(%esp)
80104271:	e8 74 0b 00 00       	call   80104dea <wakeup>
80104276:	eb 1d                	jmp    80104295 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104278:	8b 45 08             	mov    0x8(%ebp),%eax
8010427b:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104282:	00 00 00 
    wakeup(&p->nwrite);
80104285:	8b 45 08             	mov    0x8(%ebp),%eax
80104288:	05 38 02 00 00       	add    $0x238,%eax
8010428d:	89 04 24             	mov    %eax,(%esp)
80104290:	e8 55 0b 00 00       	call   80104dea <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104295:	8b 45 08             	mov    0x8(%ebp),%eax
80104298:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010429e:	85 c0                	test   %eax,%eax
801042a0:	75 25                	jne    801042c7 <pipeclose+0x85>
801042a2:	8b 45 08             	mov    0x8(%ebp),%eax
801042a5:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801042ab:	85 c0                	test   %eax,%eax
801042ad:	75 18                	jne    801042c7 <pipeclose+0x85>
    release(&p->lock);
801042af:	8b 45 08             	mov    0x8(%ebp),%eax
801042b2:	89 04 24             	mov    %eax,(%esp)
801042b5:	e8 83 0d 00 00       	call   8010503d <release>
    kfree((char*)p);
801042ba:	8b 45 08             	mov    0x8(%ebp),%eax
801042bd:	89 04 24             	mov    %eax,(%esp)
801042c0:	e8 71 e9 ff ff       	call   80102c36 <kfree>
801042c5:	eb 0b                	jmp    801042d2 <pipeclose+0x90>
  } else
    release(&p->lock);
801042c7:	8b 45 08             	mov    0x8(%ebp),%eax
801042ca:	89 04 24             	mov    %eax,(%esp)
801042cd:	e8 6b 0d 00 00       	call   8010503d <release>
}
801042d2:	c9                   	leave  
801042d3:	c3                   	ret    

801042d4 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801042d4:	55                   	push   %ebp
801042d5:	89 e5                	mov    %esp,%ebp
801042d7:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
801042da:	8b 45 08             	mov    0x8(%ebp),%eax
801042dd:	89 04 24             	mov    %eax,(%esp)
801042e0:	e8 f6 0c 00 00       	call   80104fdb <acquire>
  for(i = 0; i < n; i++){
801042e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801042ec:	e9 a6 00 00 00       	jmp    80104397 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801042f1:	eb 57                	jmp    8010434a <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801042f3:	8b 45 08             	mov    0x8(%ebp),%eax
801042f6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801042fc:	85 c0                	test   %eax,%eax
801042fe:	74 0d                	je     8010430d <pipewrite+0x39>
80104300:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104306:	8b 40 24             	mov    0x24(%eax),%eax
80104309:	85 c0                	test   %eax,%eax
8010430b:	74 15                	je     80104322 <pipewrite+0x4e>
        release(&p->lock);
8010430d:	8b 45 08             	mov    0x8(%ebp),%eax
80104310:	89 04 24             	mov    %eax,(%esp)
80104313:	e8 25 0d 00 00       	call   8010503d <release>
        return -1;
80104318:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010431d:	e9 9f 00 00 00       	jmp    801043c1 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104322:	8b 45 08             	mov    0x8(%ebp),%eax
80104325:	05 34 02 00 00       	add    $0x234,%eax
8010432a:	89 04 24             	mov    %eax,(%esp)
8010432d:	e8 b8 0a 00 00       	call   80104dea <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104332:	8b 45 08             	mov    0x8(%ebp),%eax
80104335:	8b 55 08             	mov    0x8(%ebp),%edx
80104338:	81 c2 38 02 00 00    	add    $0x238,%edx
8010433e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104342:	89 14 24             	mov    %edx,(%esp)
80104345:	e8 c7 09 00 00       	call   80104d11 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010434a:	8b 45 08             	mov    0x8(%ebp),%eax
8010434d:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104353:	8b 45 08             	mov    0x8(%ebp),%eax
80104356:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010435c:	05 00 02 00 00       	add    $0x200,%eax
80104361:	39 c2                	cmp    %eax,%edx
80104363:	74 8e                	je     801042f3 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104365:	8b 45 08             	mov    0x8(%ebp),%eax
80104368:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010436e:	8d 48 01             	lea    0x1(%eax),%ecx
80104371:	8b 55 08             	mov    0x8(%ebp),%edx
80104374:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010437a:	25 ff 01 00 00       	and    $0x1ff,%eax
8010437f:	89 c1                	mov    %eax,%ecx
80104381:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104384:	8b 45 0c             	mov    0xc(%ebp),%eax
80104387:	01 d0                	add    %edx,%eax
80104389:	0f b6 10             	movzbl (%eax),%edx
8010438c:	8b 45 08             	mov    0x8(%ebp),%eax
8010438f:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104393:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010439a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010439d:	0f 8c 4e ff ff ff    	jl     801042f1 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801043a3:	8b 45 08             	mov    0x8(%ebp),%eax
801043a6:	05 34 02 00 00       	add    $0x234,%eax
801043ab:	89 04 24             	mov    %eax,(%esp)
801043ae:	e8 37 0a 00 00       	call   80104dea <wakeup>
  release(&p->lock);
801043b3:	8b 45 08             	mov    0x8(%ebp),%eax
801043b6:	89 04 24             	mov    %eax,(%esp)
801043b9:	e8 7f 0c 00 00       	call   8010503d <release>
  return n;
801043be:	8b 45 10             	mov    0x10(%ebp),%eax
}
801043c1:	c9                   	leave  
801043c2:	c3                   	ret    

801043c3 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801043c3:	55                   	push   %ebp
801043c4:	89 e5                	mov    %esp,%ebp
801043c6:	53                   	push   %ebx
801043c7:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801043ca:	8b 45 08             	mov    0x8(%ebp),%eax
801043cd:	89 04 24             	mov    %eax,(%esp)
801043d0:	e8 06 0c 00 00       	call   80104fdb <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801043d5:	eb 3a                	jmp    80104411 <piperead+0x4e>
    if(proc->killed){
801043d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043dd:	8b 40 24             	mov    0x24(%eax),%eax
801043e0:	85 c0                	test   %eax,%eax
801043e2:	74 15                	je     801043f9 <piperead+0x36>
      release(&p->lock);
801043e4:	8b 45 08             	mov    0x8(%ebp),%eax
801043e7:	89 04 24             	mov    %eax,(%esp)
801043ea:	e8 4e 0c 00 00       	call   8010503d <release>
      return -1;
801043ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f4:	e9 b5 00 00 00       	jmp    801044ae <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801043f9:	8b 45 08             	mov    0x8(%ebp),%eax
801043fc:	8b 55 08             	mov    0x8(%ebp),%edx
801043ff:	81 c2 34 02 00 00    	add    $0x234,%edx
80104405:	89 44 24 04          	mov    %eax,0x4(%esp)
80104409:	89 14 24             	mov    %edx,(%esp)
8010440c:	e8 00 09 00 00       	call   80104d11 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104411:	8b 45 08             	mov    0x8(%ebp),%eax
80104414:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010441a:	8b 45 08             	mov    0x8(%ebp),%eax
8010441d:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104423:	39 c2                	cmp    %eax,%edx
80104425:	75 0d                	jne    80104434 <piperead+0x71>
80104427:	8b 45 08             	mov    0x8(%ebp),%eax
8010442a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104430:	85 c0                	test   %eax,%eax
80104432:	75 a3                	jne    801043d7 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104434:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010443b:	eb 4b                	jmp    80104488 <piperead+0xc5>
    if(p->nread == p->nwrite)
8010443d:	8b 45 08             	mov    0x8(%ebp),%eax
80104440:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104446:	8b 45 08             	mov    0x8(%ebp),%eax
80104449:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010444f:	39 c2                	cmp    %eax,%edx
80104451:	75 02                	jne    80104455 <piperead+0x92>
      break;
80104453:	eb 3b                	jmp    80104490 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104455:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104458:	8b 45 0c             	mov    0xc(%ebp),%eax
8010445b:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010445e:	8b 45 08             	mov    0x8(%ebp),%eax
80104461:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104467:	8d 48 01             	lea    0x1(%eax),%ecx
8010446a:	8b 55 08             	mov    0x8(%ebp),%edx
8010446d:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104473:	25 ff 01 00 00       	and    $0x1ff,%eax
80104478:	89 c2                	mov    %eax,%edx
8010447a:	8b 45 08             	mov    0x8(%ebp),%eax
8010447d:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104482:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104484:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010448b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010448e:	7c ad                	jl     8010443d <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104490:	8b 45 08             	mov    0x8(%ebp),%eax
80104493:	05 38 02 00 00       	add    $0x238,%eax
80104498:	89 04 24             	mov    %eax,(%esp)
8010449b:	e8 4a 09 00 00       	call   80104dea <wakeup>
  release(&p->lock);
801044a0:	8b 45 08             	mov    0x8(%ebp),%eax
801044a3:	89 04 24             	mov    %eax,(%esp)
801044a6:	e8 92 0b 00 00       	call   8010503d <release>
  return i;
801044ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801044ae:	83 c4 24             	add    $0x24,%esp
801044b1:	5b                   	pop    %ebx
801044b2:	5d                   	pop    %ebp
801044b3:	c3                   	ret    

801044b4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801044b4:	55                   	push   %ebp
801044b5:	89 e5                	mov    %esp,%ebp
801044b7:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801044ba:	9c                   	pushf  
801044bb:	58                   	pop    %eax
801044bc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801044bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801044c2:	c9                   	leave  
801044c3:	c3                   	ret    

801044c4 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801044c4:	55                   	push   %ebp
801044c5:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801044c7:	fb                   	sti    
}
801044c8:	5d                   	pop    %ebp
801044c9:	c3                   	ret    

801044ca <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801044ca:	55                   	push   %ebp
801044cb:	89 e5                	mov    %esp,%ebp
801044cd:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801044d0:	c7 44 24 04 ed 88 10 	movl   $0x801088ed,0x4(%esp)
801044d7:	80 
801044d8:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801044df:	e8 d6 0a 00 00       	call   80104fba <initlock>
}
801044e4:	c9                   	leave  
801044e5:	c3                   	ret    

801044e6 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801044e6:	55                   	push   %ebp
801044e7:	89 e5                	mov    %esp,%ebp
801044e9:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801044ec:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801044f3:	e8 e3 0a 00 00       	call   80104fdb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801044f8:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801044ff:	eb 50                	jmp    80104551 <allocproc+0x6b>
    if(p->state == UNUSED)
80104501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104504:	8b 40 0c             	mov    0xc(%eax),%eax
80104507:	85 c0                	test   %eax,%eax
80104509:	75 42                	jne    8010454d <allocproc+0x67>
      goto found;
8010450b:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010450c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010450f:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104516:	a1 04 b0 10 80       	mov    0x8010b004,%eax
8010451b:	8d 50 01             	lea    0x1(%eax),%edx
8010451e:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
80104524:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104527:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
8010452a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104531:	e8 07 0b 00 00       	call   8010503d <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104536:	e8 94 e7 ff ff       	call   80102ccf <kalloc>
8010453b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010453e:	89 42 08             	mov    %eax,0x8(%edx)
80104541:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104544:	8b 40 08             	mov    0x8(%eax),%eax
80104547:	85 c0                	test   %eax,%eax
80104549:	75 33                	jne    8010457e <allocproc+0x98>
8010454b:	eb 20                	jmp    8010456d <allocproc+0x87>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010454d:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104551:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104558:	72 a7                	jb     80104501 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010455a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104561:	e8 d7 0a 00 00       	call   8010503d <release>
  return 0;
80104566:	b8 00 00 00 00       	mov    $0x0,%eax
8010456b:	eb 76                	jmp    801045e3 <allocproc+0xfd>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
8010456d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104570:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104577:	b8 00 00 00 00       	mov    $0x0,%eax
8010457c:	eb 65                	jmp    801045e3 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010457e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104581:	8b 40 08             	mov    0x8(%eax),%eax
80104584:	05 00 10 00 00       	add    $0x1000,%eax
80104589:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
8010458c:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104590:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104593:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104596:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104599:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010459d:	ba 43 66 10 80       	mov    $0x80106643,%edx
801045a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045a5:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801045a7:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801045ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ae:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045b1:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801045b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b7:	8b 40 1c             	mov    0x1c(%eax),%eax
801045ba:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801045c1:	00 
801045c2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045c9:	00 
801045ca:	89 04 24             	mov    %eax,(%esp)
801045cd:	e8 5d 0c 00 00       	call   8010522f <memset>
  p->context->eip = (uint)forkret;
801045d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d5:	8b 40 1c             	mov    0x1c(%eax),%eax
801045d8:	ba d2 4c 10 80       	mov    $0x80104cd2,%edx
801045dd:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801045e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801045e3:	c9                   	leave  
801045e4:	c3                   	ret    

801045e5 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801045e5:	55                   	push   %ebp
801045e6:	89 e5                	mov    %esp,%ebp
801045e8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801045eb:	e8 f6 fe ff ff       	call   801044e6 <allocproc>
801045f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801045f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f6:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
801045fb:	e8 37 37 00 00       	call   80107d37 <setupkvm>
80104600:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104603:	89 42 04             	mov    %eax,0x4(%edx)
80104606:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104609:	8b 40 04             	mov    0x4(%eax),%eax
8010460c:	85 c0                	test   %eax,%eax
8010460e:	75 0c                	jne    8010461c <userinit+0x37>
    panic("userinit: out of memory?");
80104610:	c7 04 24 f4 88 10 80 	movl   $0x801088f4,(%esp)
80104617:	e8 1e bf ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010461c:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104624:	8b 40 04             	mov    0x4(%eax),%eax
80104627:	89 54 24 08          	mov    %edx,0x8(%esp)
8010462b:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104632:	80 
80104633:	89 04 24             	mov    %eax,(%esp)
80104636:	e8 54 39 00 00       	call   80107f8f <inituvm>
  p->sz = PGSIZE;
8010463b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104647:	8b 40 18             	mov    0x18(%eax),%eax
8010464a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104651:	00 
80104652:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104659:	00 
8010465a:	89 04 24             	mov    %eax,(%esp)
8010465d:	e8 cd 0b 00 00       	call   8010522f <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104662:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104665:	8b 40 18             	mov    0x18(%eax),%eax
80104668:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010466e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104671:	8b 40 18             	mov    0x18(%eax),%eax
80104674:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010467a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467d:	8b 40 18             	mov    0x18(%eax),%eax
80104680:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104683:	8b 52 18             	mov    0x18(%edx),%edx
80104686:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010468a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010468e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104691:	8b 40 18             	mov    0x18(%eax),%eax
80104694:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104697:	8b 52 18             	mov    0x18(%edx),%edx
8010469a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010469e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801046a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a5:	8b 40 18             	mov    0x18(%eax),%eax
801046a8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801046af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b2:	8b 40 18             	mov    0x18(%eax),%eax
801046b5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801046bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046bf:	8b 40 18             	mov    0x18(%eax),%eax
801046c2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801046c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046cc:	83 c0 6c             	add    $0x6c,%eax
801046cf:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801046d6:	00 
801046d7:	c7 44 24 04 0d 89 10 	movl   $0x8010890d,0x4(%esp)
801046de:	80 
801046df:	89 04 24             	mov    %eax,(%esp)
801046e2:	e8 68 0d 00 00       	call   8010544f <safestrcpy>
  p->cwd = namei("/");
801046e7:	c7 04 24 16 89 10 80 	movl   $0x80108916,(%esp)
801046ee:	e8 c9 de ff ff       	call   801025bc <namei>
801046f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046f6:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801046f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046fc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104703:	c9                   	leave  
80104704:	c3                   	ret    

80104705 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104705:	55                   	push   %ebp
80104706:	89 e5                	mov    %esp,%ebp
80104708:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010470b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104711:	8b 00                	mov    (%eax),%eax
80104713:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104716:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010471a:	7e 34                	jle    80104750 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010471c:	8b 55 08             	mov    0x8(%ebp),%edx
8010471f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104722:	01 c2                	add    %eax,%edx
80104724:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010472a:	8b 40 04             	mov    0x4(%eax),%eax
8010472d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104731:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104734:	89 54 24 04          	mov    %edx,0x4(%esp)
80104738:	89 04 24             	mov    %eax,(%esp)
8010473b:	e8 c5 39 00 00       	call   80108105 <allocuvm>
80104740:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104743:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104747:	75 41                	jne    8010478a <growproc+0x85>
      return -1;
80104749:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010474e:	eb 58                	jmp    801047a8 <growproc+0xa3>
  } else if(n < 0){
80104750:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104754:	79 34                	jns    8010478a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104756:	8b 55 08             	mov    0x8(%ebp),%edx
80104759:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010475c:	01 c2                	add    %eax,%edx
8010475e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104764:	8b 40 04             	mov    0x4(%eax),%eax
80104767:	89 54 24 08          	mov    %edx,0x8(%esp)
8010476b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010476e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104772:	89 04 24             	mov    %eax,(%esp)
80104775:	e8 65 3a 00 00       	call   801081df <deallocuvm>
8010477a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010477d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104781:	75 07                	jne    8010478a <growproc+0x85>
      return -1;
80104783:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104788:	eb 1e                	jmp    801047a8 <growproc+0xa3>
  }
  proc->sz = sz;
8010478a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104790:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104793:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104795:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010479b:	89 04 24             	mov    %eax,(%esp)
8010479e:	e8 85 36 00 00       	call   80107e28 <switchuvm>
  return 0;
801047a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047a8:	c9                   	leave  
801047a9:	c3                   	ret    

801047aa <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801047aa:	55                   	push   %ebp
801047ab:	89 e5                	mov    %esp,%ebp
801047ad:	57                   	push   %edi
801047ae:	56                   	push   %esi
801047af:	53                   	push   %ebx
801047b0:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801047b3:	e8 2e fd ff ff       	call   801044e6 <allocproc>
801047b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
801047bb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801047bf:	75 0a                	jne    801047cb <fork+0x21>
    return -1;
801047c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c6:	e9 52 01 00 00       	jmp    8010491d <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801047cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047d1:	8b 10                	mov    (%eax),%edx
801047d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047d9:	8b 40 04             	mov    0x4(%eax),%eax
801047dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801047e0:	89 04 24             	mov    %eax,(%esp)
801047e3:	e8 93 3b 00 00       	call   8010837b <copyuvm>
801047e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801047eb:	89 42 04             	mov    %eax,0x4(%edx)
801047ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047f1:	8b 40 04             	mov    0x4(%eax),%eax
801047f4:	85 c0                	test   %eax,%eax
801047f6:	75 2c                	jne    80104824 <fork+0x7a>
    kfree(np->kstack);
801047f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047fb:	8b 40 08             	mov    0x8(%eax),%eax
801047fe:	89 04 24             	mov    %eax,(%esp)
80104801:	e8 30 e4 ff ff       	call   80102c36 <kfree>
    np->kstack = 0;
80104806:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104809:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104810:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104813:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010481a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010481f:	e9 f9 00 00 00       	jmp    8010491d <fork+0x173>
  }
  np->sz = proc->sz;
80104824:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010482a:	8b 10                	mov    (%eax),%edx
8010482c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010482f:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104831:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104838:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010483b:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010483e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104841:	8b 50 18             	mov    0x18(%eax),%edx
80104844:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484a:	8b 40 18             	mov    0x18(%eax),%eax
8010484d:	89 c3                	mov    %eax,%ebx
8010484f:	b8 13 00 00 00       	mov    $0x13,%eax
80104854:	89 d7                	mov    %edx,%edi
80104856:	89 de                	mov    %ebx,%esi
80104858:	89 c1                	mov    %eax,%ecx
8010485a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010485c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010485f:	8b 40 18             	mov    0x18(%eax),%eax
80104862:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104869:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104870:	eb 3d                	jmp    801048af <fork+0x105>
    if(proc->ofile[i])
80104872:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104878:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010487b:	83 c2 08             	add    $0x8,%edx
8010487e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104882:	85 c0                	test   %eax,%eax
80104884:	74 25                	je     801048ab <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104886:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010488c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010488f:	83 c2 08             	add    $0x8,%edx
80104892:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104896:	89 04 24             	mov    %eax,(%esp)
80104899:	e8 03 c7 ff ff       	call   80100fa1 <filedup>
8010489e:	8b 55 e0             	mov    -0x20(%ebp),%edx
801048a1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801048a4:	83 c1 08             	add    $0x8,%ecx
801048a7:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801048ab:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801048af:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801048b3:	7e bd                	jle    80104872 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801048b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048bb:	8b 40 68             	mov    0x68(%eax),%eax
801048be:	89 04 24             	mov    %eax,(%esp)
801048c1:	e8 dc cf ff ff       	call   801018a2 <idup>
801048c6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801048c9:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
801048cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d2:	8d 50 6c             	lea    0x6c(%eax),%edx
801048d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048d8:	83 c0 6c             	add    $0x6c,%eax
801048db:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801048e2:	00 
801048e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801048e7:	89 04 24             	mov    %eax,(%esp)
801048ea:	e8 60 0b 00 00       	call   8010544f <safestrcpy>
 
  pid = np->pid;
801048ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048f2:	8b 40 10             	mov    0x10(%eax),%eax
801048f5:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
801048f8:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801048ff:	e8 d7 06 00 00       	call   80104fdb <acquire>
  np->state = RUNNABLE;
80104904:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104907:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
8010490e:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104915:	e8 23 07 00 00       	call   8010503d <release>
  
  return pid;
8010491a:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010491d:	83 c4 2c             	add    $0x2c,%esp
80104920:	5b                   	pop    %ebx
80104921:	5e                   	pop    %esi
80104922:	5f                   	pop    %edi
80104923:	5d                   	pop    %ebp
80104924:	c3                   	ret    

80104925 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104925:	55                   	push   %ebp
80104926:	89 e5                	mov    %esp,%ebp
80104928:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010492b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104932:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104937:	39 c2                	cmp    %eax,%edx
80104939:	75 0c                	jne    80104947 <exit+0x22>
    panic("init exiting");
8010493b:	c7 04 24 18 89 10 80 	movl   $0x80108918,(%esp)
80104942:	e8 f3 bb ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104947:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010494e:	eb 44                	jmp    80104994 <exit+0x6f>
    if(proc->ofile[fd]){
80104950:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104956:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104959:	83 c2 08             	add    $0x8,%edx
8010495c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104960:	85 c0                	test   %eax,%eax
80104962:	74 2c                	je     80104990 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104964:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010496a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010496d:	83 c2 08             	add    $0x8,%edx
80104970:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104974:	89 04 24             	mov    %eax,(%esp)
80104977:	e8 6d c6 ff ff       	call   80100fe9 <fileclose>
      proc->ofile[fd] = 0;
8010497c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104982:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104985:	83 c2 08             	add    $0x8,%edx
80104988:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010498f:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104990:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104994:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104998:	7e b6                	jle    80104950 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
8010499a:	e8 54 ec ff ff       	call   801035f3 <begin_op>
  iput(proc->cwd);
8010499f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a5:	8b 40 68             	mov    0x68(%eax),%eax
801049a8:	89 04 24             	mov    %eax,(%esp)
801049ab:	e8 dd d0 ff ff       	call   80101a8d <iput>
  end_op();
801049b0:	e8 c2 ec ff ff       	call   80103677 <end_op>
  proc->cwd = 0;
801049b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049bb:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801049c2:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801049c9:	e8 0d 06 00 00       	call   80104fdb <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801049ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d4:	8b 40 14             	mov    0x14(%eax),%eax
801049d7:	89 04 24             	mov    %eax,(%esp)
801049da:	e8 cd 03 00 00       	call   80104dac <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049df:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801049e6:	eb 38                	jmp    80104a20 <exit+0xfb>
    if(p->parent == proc){
801049e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049eb:	8b 50 14             	mov    0x14(%eax),%edx
801049ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049f4:	39 c2                	cmp    %eax,%edx
801049f6:	75 24                	jne    80104a1c <exit+0xf7>
      p->parent = initproc;
801049f8:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
801049fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a01:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104a04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a07:	8b 40 0c             	mov    0xc(%eax),%eax
80104a0a:	83 f8 05             	cmp    $0x5,%eax
80104a0d:	75 0d                	jne    80104a1c <exit+0xf7>
        wakeup1(initproc);
80104a0f:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104a14:	89 04 24             	mov    %eax,(%esp)
80104a17:	e8 90 03 00 00       	call   80104dac <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a1c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a20:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104a27:	72 bf                	jb     801049e8 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104a29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a2f:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104a36:	e8 b3 01 00 00       	call   80104bee <sched>
  panic("zombie exit");
80104a3b:	c7 04 24 25 89 10 80 	movl   $0x80108925,(%esp)
80104a42:	e8 f3 ba ff ff       	call   8010053a <panic>

80104a47 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104a47:	55                   	push   %ebp
80104a48:	89 e5                	mov    %esp,%ebp
80104a4a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104a4d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a54:	e8 82 05 00 00       	call   80104fdb <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104a59:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a60:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104a67:	e9 9a 00 00 00       	jmp    80104b06 <wait+0xbf>
      if(p->parent != proc)
80104a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6f:	8b 50 14             	mov    0x14(%eax),%edx
80104a72:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a78:	39 c2                	cmp    %eax,%edx
80104a7a:	74 05                	je     80104a81 <wait+0x3a>
        continue;
80104a7c:	e9 81 00 00 00       	jmp    80104b02 <wait+0xbb>
      havekids = 1;
80104a81:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8b:	8b 40 0c             	mov    0xc(%eax),%eax
80104a8e:	83 f8 05             	cmp    $0x5,%eax
80104a91:	75 6f                	jne    80104b02 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a96:	8b 40 10             	mov    0x10(%eax),%eax
80104a99:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a9f:	8b 40 08             	mov    0x8(%eax),%eax
80104aa2:	89 04 24             	mov    %eax,(%esp)
80104aa5:	e8 8c e1 ff ff       	call   80102c36 <kfree>
        p->kstack = 0;
80104aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aad:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab7:	8b 40 04             	mov    0x4(%eax),%eax
80104aba:	89 04 24             	mov    %eax,(%esp)
80104abd:	e8 d9 37 00 00       	call   8010829b <freevm>
        p->state = UNUSED;
80104ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104acf:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae3:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aea:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104af1:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104af8:	e8 40 05 00 00       	call   8010503d <release>
        return pid;
80104afd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b00:	eb 52                	jmp    80104b54 <wait+0x10d>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b02:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104b06:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104b0d:	0f 82 59 ff ff ff    	jb     80104a6c <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104b13:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104b17:	74 0d                	je     80104b26 <wait+0xdf>
80104b19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b1f:	8b 40 24             	mov    0x24(%eax),%eax
80104b22:	85 c0                	test   %eax,%eax
80104b24:	74 13                	je     80104b39 <wait+0xf2>
      release(&ptable.lock);
80104b26:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b2d:	e8 0b 05 00 00       	call   8010503d <release>
      return -1;
80104b32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b37:	eb 1b                	jmp    80104b54 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104b39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b3f:	c7 44 24 04 60 29 11 	movl   $0x80112960,0x4(%esp)
80104b46:	80 
80104b47:	89 04 24             	mov    %eax,(%esp)
80104b4a:	e8 c2 01 00 00       	call   80104d11 <sleep>
  }
80104b4f:	e9 05 ff ff ff       	jmp    80104a59 <wait+0x12>
}
80104b54:	c9                   	leave  
80104b55:	c3                   	ret    

80104b56 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b56:	55                   	push   %ebp
80104b57:	89 e5                	mov    %esp,%ebp
80104b59:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b5c:	e8 63 f9 ff ff       	call   801044c4 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b61:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b68:	e8 6e 04 00 00       	call   80104fdb <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b6d:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104b74:	eb 5e                	jmp    80104bd4 <scheduler+0x7e>
      if(p->state != RUNNABLE)
80104b76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b79:	8b 40 0c             	mov    0xc(%eax),%eax
80104b7c:	83 f8 03             	cmp    $0x3,%eax
80104b7f:	74 02                	je     80104b83 <scheduler+0x2d>
        continue;
80104b81:	eb 4d                	jmp    80104bd0 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b86:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b8f:	89 04 24             	mov    %eax,(%esp)
80104b92:	e8 91 32 00 00       	call   80107e28 <switchuvm>
      p->state = RUNNING;
80104b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9a:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104ba1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ba7:	8b 40 1c             	mov    0x1c(%eax),%eax
80104baa:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104bb1:	83 c2 04             	add    $0x4,%edx
80104bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bb8:	89 14 24             	mov    %edx,(%esp)
80104bbb:	e8 00 09 00 00       	call   801054c0 <swtch>
      switchkvm();
80104bc0:	e8 46 32 00 00       	call   80107e0b <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104bc5:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104bcc:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bd0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104bd4:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104bdb:	72 99                	jb     80104b76 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104bdd:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104be4:	e8 54 04 00 00       	call   8010503d <release>

  }
80104be9:	e9 6e ff ff ff       	jmp    80104b5c <scheduler+0x6>

80104bee <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104bee:	55                   	push   %ebp
80104bef:	89 e5                	mov    %esp,%ebp
80104bf1:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104bf4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bfb:	e8 05 05 00 00       	call   80105105 <holding>
80104c00:	85 c0                	test   %eax,%eax
80104c02:	75 0c                	jne    80104c10 <sched+0x22>
    panic("sched ptable.lock");
80104c04:	c7 04 24 31 89 10 80 	movl   $0x80108931,(%esp)
80104c0b:	e8 2a b9 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104c10:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c16:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c1c:	83 f8 01             	cmp    $0x1,%eax
80104c1f:	74 0c                	je     80104c2d <sched+0x3f>
    panic("sched locks");
80104c21:	c7 04 24 43 89 10 80 	movl   $0x80108943,(%esp)
80104c28:	e8 0d b9 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104c2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c33:	8b 40 0c             	mov    0xc(%eax),%eax
80104c36:	83 f8 04             	cmp    $0x4,%eax
80104c39:	75 0c                	jne    80104c47 <sched+0x59>
    panic("sched running");
80104c3b:	c7 04 24 4f 89 10 80 	movl   $0x8010894f,(%esp)
80104c42:	e8 f3 b8 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104c47:	e8 68 f8 ff ff       	call   801044b4 <readeflags>
80104c4c:	25 00 02 00 00       	and    $0x200,%eax
80104c51:	85 c0                	test   %eax,%eax
80104c53:	74 0c                	je     80104c61 <sched+0x73>
    panic("sched interruptible");
80104c55:	c7 04 24 5d 89 10 80 	movl   $0x8010895d,(%esp)
80104c5c:	e8 d9 b8 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104c61:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c67:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104c6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104c70:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c76:	8b 40 04             	mov    0x4(%eax),%eax
80104c79:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104c80:	83 c2 1c             	add    $0x1c,%edx
80104c83:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c87:	89 14 24             	mov    %edx,(%esp)
80104c8a:	e8 31 08 00 00       	call   801054c0 <swtch>
  cpu->intena = intena;
80104c8f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c98:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104c9e:	c9                   	leave  
80104c9f:	c3                   	ret    

80104ca0 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ca0:	55                   	push   %ebp
80104ca1:	89 e5                	mov    %esp,%ebp
80104ca3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ca6:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cad:	e8 29 03 00 00       	call   80104fdb <acquire>
  proc->state = RUNNABLE;
80104cb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cb8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104cbf:	e8 2a ff ff ff       	call   80104bee <sched>
  release(&ptable.lock);
80104cc4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ccb:	e8 6d 03 00 00       	call   8010503d <release>
}
80104cd0:	c9                   	leave  
80104cd1:	c3                   	ret    

80104cd2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104cd2:	55                   	push   %ebp
80104cd3:	89 e5                	mov    %esp,%ebp
80104cd5:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104cd8:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cdf:	e8 59 03 00 00       	call   8010503d <release>

  if (first) {
80104ce4:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104ce9:	85 c0                	test   %eax,%eax
80104ceb:	74 22                	je     80104d0f <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104ced:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104cf4:	00 00 00 
    iinit(ROOTDEV);
80104cf7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80104cfe:	e8 a9 c8 ff ff       	call   801015ac <iinit>
    initlog(ROOTDEV);
80104d03:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80104d0a:	e8 e0 e6 ff ff       	call   801033ef <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104d0f:	c9                   	leave  
80104d10:	c3                   	ret    

80104d11 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104d11:	55                   	push   %ebp
80104d12:	89 e5                	mov    %esp,%ebp
80104d14:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104d17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d1d:	85 c0                	test   %eax,%eax
80104d1f:	75 0c                	jne    80104d2d <sleep+0x1c>
    panic("sleep");
80104d21:	c7 04 24 71 89 10 80 	movl   $0x80108971,(%esp)
80104d28:	e8 0d b8 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104d2d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104d31:	75 0c                	jne    80104d3f <sleep+0x2e>
    panic("sleep without lk");
80104d33:	c7 04 24 77 89 10 80 	movl   $0x80108977,(%esp)
80104d3a:	e8 fb b7 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104d3f:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104d46:	74 17                	je     80104d5f <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104d48:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d4f:	e8 87 02 00 00       	call   80104fdb <acquire>
    release(lk);
80104d54:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d57:	89 04 24             	mov    %eax,(%esp)
80104d5a:	e8 de 02 00 00       	call   8010503d <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104d5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d65:	8b 55 08             	mov    0x8(%ebp),%edx
80104d68:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104d6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d71:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104d78:	e8 71 fe ff ff       	call   80104bee <sched>

  // Tidy up.
  proc->chan = 0;
80104d7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d83:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104d8a:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104d91:	74 17                	je     80104daa <sleep+0x99>
    release(&ptable.lock);
80104d93:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d9a:	e8 9e 02 00 00       	call   8010503d <release>
    acquire(lk);
80104d9f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104da2:	89 04 24             	mov    %eax,(%esp)
80104da5:	e8 31 02 00 00       	call   80104fdb <acquire>
  }
}
80104daa:	c9                   	leave  
80104dab:	c3                   	ret    

80104dac <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104dac:	55                   	push   %ebp
80104dad:	89 e5                	mov    %esp,%ebp
80104daf:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104db2:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104db9:	eb 24                	jmp    80104ddf <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104dbb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dbe:	8b 40 0c             	mov    0xc(%eax),%eax
80104dc1:	83 f8 02             	cmp    $0x2,%eax
80104dc4:	75 15                	jne    80104ddb <wakeup1+0x2f>
80104dc6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dc9:	8b 40 20             	mov    0x20(%eax),%eax
80104dcc:	3b 45 08             	cmp    0x8(%ebp),%eax
80104dcf:	75 0a                	jne    80104ddb <wakeup1+0x2f>
      p->state = RUNNABLE;
80104dd1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dd4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ddb:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104ddf:	81 7d fc 94 48 11 80 	cmpl   $0x80114894,-0x4(%ebp)
80104de6:	72 d3                	jb     80104dbb <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104de8:	c9                   	leave  
80104de9:	c3                   	ret    

80104dea <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104dea:	55                   	push   %ebp
80104deb:	89 e5                	mov    %esp,%ebp
80104ded:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104df0:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104df7:	e8 df 01 00 00       	call   80104fdb <acquire>
  wakeup1(chan);
80104dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80104dff:	89 04 24             	mov    %eax,(%esp)
80104e02:	e8 a5 ff ff ff       	call   80104dac <wakeup1>
  release(&ptable.lock);
80104e07:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e0e:	e8 2a 02 00 00       	call   8010503d <release>
}
80104e13:	c9                   	leave  
80104e14:	c3                   	ret    

80104e15 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104e15:	55                   	push   %ebp
80104e16:	89 e5                	mov    %esp,%ebp
80104e18:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104e1b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e22:	e8 b4 01 00 00       	call   80104fdb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e27:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104e2e:	eb 41                	jmp    80104e71 <kill+0x5c>
    if(p->pid == pid){
80104e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e33:	8b 40 10             	mov    0x10(%eax),%eax
80104e36:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e39:	75 32                	jne    80104e6d <kill+0x58>
      p->killed = 1;
80104e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e3e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e48:	8b 40 0c             	mov    0xc(%eax),%eax
80104e4b:	83 f8 02             	cmp    $0x2,%eax
80104e4e:	75 0a                	jne    80104e5a <kill+0x45>
        p->state = RUNNABLE;
80104e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e53:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104e5a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e61:	e8 d7 01 00 00       	call   8010503d <release>
      return 0;
80104e66:	b8 00 00 00 00       	mov    $0x0,%eax
80104e6b:	eb 1e                	jmp    80104e8b <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e6d:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104e71:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104e78:	72 b6                	jb     80104e30 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104e7a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e81:	e8 b7 01 00 00       	call   8010503d <release>
  return -1;
80104e86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e8b:	c9                   	leave  
80104e8c:	c3                   	ret    

80104e8d <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104e8d:	55                   	push   %ebp
80104e8e:	89 e5                	mov    %esp,%ebp
80104e90:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e93:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104e9a:	e9 d6 00 00 00       	jmp    80104f75 <procdump+0xe8>
    if(p->state == UNUSED)
80104e9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ea2:	8b 40 0c             	mov    0xc(%eax),%eax
80104ea5:	85 c0                	test   %eax,%eax
80104ea7:	75 05                	jne    80104eae <procdump+0x21>
      continue;
80104ea9:	e9 c3 00 00 00       	jmp    80104f71 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104eae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104eb1:	8b 40 0c             	mov    0xc(%eax),%eax
80104eb4:	83 f8 05             	cmp    $0x5,%eax
80104eb7:	77 23                	ja     80104edc <procdump+0x4f>
80104eb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ebc:	8b 40 0c             	mov    0xc(%eax),%eax
80104ebf:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104ec6:	85 c0                	test   %eax,%eax
80104ec8:	74 12                	je     80104edc <procdump+0x4f>
      state = states[p->state];
80104eca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ecd:	8b 40 0c             	mov    0xc(%eax),%eax
80104ed0:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104ed7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104eda:	eb 07                	jmp    80104ee3 <procdump+0x56>
    else
      state = "???";
80104edc:	c7 45 ec 88 89 10 80 	movl   $0x80108988,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104ee3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ee6:	8d 50 6c             	lea    0x6c(%eax),%edx
80104ee9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104eec:	8b 40 10             	mov    0x10(%eax),%eax
80104eef:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104ef3:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104ef6:	89 54 24 08          	mov    %edx,0x8(%esp)
80104efa:	89 44 24 04          	mov    %eax,0x4(%esp)
80104efe:	c7 04 24 8c 89 10 80 	movl   $0x8010898c,(%esp)
80104f05:	e8 96 b4 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104f0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f0d:	8b 40 0c             	mov    0xc(%eax),%eax
80104f10:	83 f8 02             	cmp    $0x2,%eax
80104f13:	75 50                	jne    80104f65 <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104f15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f18:	8b 40 1c             	mov    0x1c(%eax),%eax
80104f1b:	8b 40 0c             	mov    0xc(%eax),%eax
80104f1e:	83 c0 08             	add    $0x8,%eax
80104f21:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104f24:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f28:	89 04 24             	mov    %eax,(%esp)
80104f2b:	e8 5c 01 00 00       	call   8010508c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104f30:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104f37:	eb 1b                	jmp    80104f54 <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f3c:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104f40:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f44:	c7 04 24 95 89 10 80 	movl   $0x80108995,(%esp)
80104f4b:	e8 50 b4 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104f50:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104f54:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104f58:	7f 0b                	jg     80104f65 <procdump+0xd8>
80104f5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f5d:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104f61:	85 c0                	test   %eax,%eax
80104f63:	75 d4                	jne    80104f39 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104f65:	c7 04 24 99 89 10 80 	movl   $0x80108999,(%esp)
80104f6c:	e8 2f b4 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f71:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104f75:	81 7d f0 94 48 11 80 	cmpl   $0x80114894,-0x10(%ebp)
80104f7c:	0f 82 1d ff ff ff    	jb     80104e9f <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104f82:	c9                   	leave  
80104f83:	c3                   	ret    

80104f84 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104f84:	55                   	push   %ebp
80104f85:	89 e5                	mov    %esp,%ebp
80104f87:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104f8a:	9c                   	pushf  
80104f8b:	58                   	pop    %eax
80104f8c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104f8f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f92:	c9                   	leave  
80104f93:	c3                   	ret    

80104f94 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104f94:	55                   	push   %ebp
80104f95:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f97:	fa                   	cli    
}
80104f98:	5d                   	pop    %ebp
80104f99:	c3                   	ret    

80104f9a <sti>:

static inline void
sti(void)
{
80104f9a:	55                   	push   %ebp
80104f9b:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104f9d:	fb                   	sti    
}
80104f9e:	5d                   	pop    %ebp
80104f9f:	c3                   	ret    

80104fa0 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104fa0:	55                   	push   %ebp
80104fa1:	89 e5                	mov    %esp,%ebp
80104fa3:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104fa6:	8b 55 08             	mov    0x8(%ebp),%edx
80104fa9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fac:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104faf:	f0 87 02             	lock xchg %eax,(%edx)
80104fb2:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104fb5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104fb8:	c9                   	leave  
80104fb9:	c3                   	ret    

80104fba <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104fba:	55                   	push   %ebp
80104fbb:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104fbd:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc0:	8b 55 0c             	mov    0xc(%ebp),%edx
80104fc3:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104fc6:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104fcf:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104fd9:	5d                   	pop    %ebp
80104fda:	c3                   	ret    

80104fdb <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104fdb:	55                   	push   %ebp
80104fdc:	89 e5                	mov    %esp,%ebp
80104fde:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104fe1:	e8 49 01 00 00       	call   8010512f <pushcli>
  if(holding(lk))
80104fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe9:	89 04 24             	mov    %eax,(%esp)
80104fec:	e8 14 01 00 00       	call   80105105 <holding>
80104ff1:	85 c0                	test   %eax,%eax
80104ff3:	74 0c                	je     80105001 <acquire+0x26>
    panic("acquire");
80104ff5:	c7 04 24 c5 89 10 80 	movl   $0x801089c5,(%esp)
80104ffc:	e8 39 b5 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105001:	90                   	nop
80105002:	8b 45 08             	mov    0x8(%ebp),%eax
80105005:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010500c:	00 
8010500d:	89 04 24             	mov    %eax,(%esp)
80105010:	e8 8b ff ff ff       	call   80104fa0 <xchg>
80105015:	85 c0                	test   %eax,%eax
80105017:	75 e9                	jne    80105002 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105019:	8b 45 08             	mov    0x8(%ebp),%eax
8010501c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105023:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105026:	8b 45 08             	mov    0x8(%ebp),%eax
80105029:	83 c0 0c             	add    $0xc,%eax
8010502c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105030:	8d 45 08             	lea    0x8(%ebp),%eax
80105033:	89 04 24             	mov    %eax,(%esp)
80105036:	e8 51 00 00 00       	call   8010508c <getcallerpcs>
}
8010503b:	c9                   	leave  
8010503c:	c3                   	ret    

8010503d <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
8010503d:	55                   	push   %ebp
8010503e:	89 e5                	mov    %esp,%ebp
80105040:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105043:	8b 45 08             	mov    0x8(%ebp),%eax
80105046:	89 04 24             	mov    %eax,(%esp)
80105049:	e8 b7 00 00 00       	call   80105105 <holding>
8010504e:	85 c0                	test   %eax,%eax
80105050:	75 0c                	jne    8010505e <release+0x21>
    panic("release");
80105052:	c7 04 24 cd 89 10 80 	movl   $0x801089cd,(%esp)
80105059:	e8 dc b4 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
8010505e:	8b 45 08             	mov    0x8(%ebp),%eax
80105061:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105068:	8b 45 08             	mov    0x8(%ebp),%eax
8010506b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105072:	8b 45 08             	mov    0x8(%ebp),%eax
80105075:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010507c:	00 
8010507d:	89 04 24             	mov    %eax,(%esp)
80105080:	e8 1b ff ff ff       	call   80104fa0 <xchg>

  popcli();
80105085:	e8 e9 00 00 00       	call   80105173 <popcli>
}
8010508a:	c9                   	leave  
8010508b:	c3                   	ret    

8010508c <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010508c:	55                   	push   %ebp
8010508d:	89 e5                	mov    %esp,%ebp
8010508f:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105092:	8b 45 08             	mov    0x8(%ebp),%eax
80105095:	83 e8 08             	sub    $0x8,%eax
80105098:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010509b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801050a2:	eb 38                	jmp    801050dc <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801050a4:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801050a8:	74 38                	je     801050e2 <getcallerpcs+0x56>
801050aa:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801050b1:	76 2f                	jbe    801050e2 <getcallerpcs+0x56>
801050b3:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801050b7:	74 29                	je     801050e2 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
801050b9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050bc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801050c6:	01 c2                	add    %eax,%edx
801050c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050cb:	8b 40 04             	mov    0x4(%eax),%eax
801050ce:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801050d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050d3:	8b 00                	mov    (%eax),%eax
801050d5:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801050d8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050dc:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801050e0:	7e c2                	jle    801050a4 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801050e2:	eb 19                	jmp    801050fd <getcallerpcs+0x71>
    pcs[i] = 0;
801050e4:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050e7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801050f1:	01 d0                	add    %edx,%eax
801050f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801050f9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050fd:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105101:	7e e1                	jle    801050e4 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105103:	c9                   	leave  
80105104:	c3                   	ret    

80105105 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105105:	55                   	push   %ebp
80105106:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105108:	8b 45 08             	mov    0x8(%ebp),%eax
8010510b:	8b 00                	mov    (%eax),%eax
8010510d:	85 c0                	test   %eax,%eax
8010510f:	74 17                	je     80105128 <holding+0x23>
80105111:	8b 45 08             	mov    0x8(%ebp),%eax
80105114:	8b 50 08             	mov    0x8(%eax),%edx
80105117:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010511d:	39 c2                	cmp    %eax,%edx
8010511f:	75 07                	jne    80105128 <holding+0x23>
80105121:	b8 01 00 00 00       	mov    $0x1,%eax
80105126:	eb 05                	jmp    8010512d <holding+0x28>
80105128:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010512d:	5d                   	pop    %ebp
8010512e:	c3                   	ret    

8010512f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010512f:	55                   	push   %ebp
80105130:	89 e5                	mov    %esp,%ebp
80105132:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105135:	e8 4a fe ff ff       	call   80104f84 <readeflags>
8010513a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010513d:	e8 52 fe ff ff       	call   80104f94 <cli>
  if(cpu->ncli++ == 0)
80105142:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105149:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
8010514f:	8d 48 01             	lea    0x1(%eax),%ecx
80105152:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105158:	85 c0                	test   %eax,%eax
8010515a:	75 15                	jne    80105171 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
8010515c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105162:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105165:	81 e2 00 02 00 00    	and    $0x200,%edx
8010516b:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105171:	c9                   	leave  
80105172:	c3                   	ret    

80105173 <popcli>:

void
popcli(void)
{
80105173:	55                   	push   %ebp
80105174:	89 e5                	mov    %esp,%ebp
80105176:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105179:	e8 06 fe ff ff       	call   80104f84 <readeflags>
8010517e:	25 00 02 00 00       	and    $0x200,%eax
80105183:	85 c0                	test   %eax,%eax
80105185:	74 0c                	je     80105193 <popcli+0x20>
    panic("popcli - interruptible");
80105187:	c7 04 24 d5 89 10 80 	movl   $0x801089d5,(%esp)
8010518e:	e8 a7 b3 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105193:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105199:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
8010519f:	83 ea 01             	sub    $0x1,%edx
801051a2:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801051a8:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801051ae:	85 c0                	test   %eax,%eax
801051b0:	79 0c                	jns    801051be <popcli+0x4b>
    panic("popcli");
801051b2:	c7 04 24 ec 89 10 80 	movl   $0x801089ec,(%esp)
801051b9:	e8 7c b3 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
801051be:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051c4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801051ca:	85 c0                	test   %eax,%eax
801051cc:	75 15                	jne    801051e3 <popcli+0x70>
801051ce:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051d4:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801051da:	85 c0                	test   %eax,%eax
801051dc:	74 05                	je     801051e3 <popcli+0x70>
    sti();
801051de:	e8 b7 fd ff ff       	call   80104f9a <sti>
}
801051e3:	c9                   	leave  
801051e4:	c3                   	ret    

801051e5 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801051e5:	55                   	push   %ebp
801051e6:	89 e5                	mov    %esp,%ebp
801051e8:	57                   	push   %edi
801051e9:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801051ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051ed:	8b 55 10             	mov    0x10(%ebp),%edx
801051f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801051f3:	89 cb                	mov    %ecx,%ebx
801051f5:	89 df                	mov    %ebx,%edi
801051f7:	89 d1                	mov    %edx,%ecx
801051f9:	fc                   	cld    
801051fa:	f3 aa                	rep stos %al,%es:(%edi)
801051fc:	89 ca                	mov    %ecx,%edx
801051fe:	89 fb                	mov    %edi,%ebx
80105200:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105203:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105206:	5b                   	pop    %ebx
80105207:	5f                   	pop    %edi
80105208:	5d                   	pop    %ebp
80105209:	c3                   	ret    

8010520a <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
8010520a:	55                   	push   %ebp
8010520b:	89 e5                	mov    %esp,%ebp
8010520d:	57                   	push   %edi
8010520e:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010520f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105212:	8b 55 10             	mov    0x10(%ebp),%edx
80105215:	8b 45 0c             	mov    0xc(%ebp),%eax
80105218:	89 cb                	mov    %ecx,%ebx
8010521a:	89 df                	mov    %ebx,%edi
8010521c:	89 d1                	mov    %edx,%ecx
8010521e:	fc                   	cld    
8010521f:	f3 ab                	rep stos %eax,%es:(%edi)
80105221:	89 ca                	mov    %ecx,%edx
80105223:	89 fb                	mov    %edi,%ebx
80105225:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105228:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010522b:	5b                   	pop    %ebx
8010522c:	5f                   	pop    %edi
8010522d:	5d                   	pop    %ebp
8010522e:	c3                   	ret    

8010522f <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010522f:	55                   	push   %ebp
80105230:	89 e5                	mov    %esp,%ebp
80105232:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105235:	8b 45 08             	mov    0x8(%ebp),%eax
80105238:	83 e0 03             	and    $0x3,%eax
8010523b:	85 c0                	test   %eax,%eax
8010523d:	75 49                	jne    80105288 <memset+0x59>
8010523f:	8b 45 10             	mov    0x10(%ebp),%eax
80105242:	83 e0 03             	and    $0x3,%eax
80105245:	85 c0                	test   %eax,%eax
80105247:	75 3f                	jne    80105288 <memset+0x59>
    c &= 0xFF;
80105249:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105250:	8b 45 10             	mov    0x10(%ebp),%eax
80105253:	c1 e8 02             	shr    $0x2,%eax
80105256:	89 c2                	mov    %eax,%edx
80105258:	8b 45 0c             	mov    0xc(%ebp),%eax
8010525b:	c1 e0 18             	shl    $0x18,%eax
8010525e:	89 c1                	mov    %eax,%ecx
80105260:	8b 45 0c             	mov    0xc(%ebp),%eax
80105263:	c1 e0 10             	shl    $0x10,%eax
80105266:	09 c1                	or     %eax,%ecx
80105268:	8b 45 0c             	mov    0xc(%ebp),%eax
8010526b:	c1 e0 08             	shl    $0x8,%eax
8010526e:	09 c8                	or     %ecx,%eax
80105270:	0b 45 0c             	or     0xc(%ebp),%eax
80105273:	89 54 24 08          	mov    %edx,0x8(%esp)
80105277:	89 44 24 04          	mov    %eax,0x4(%esp)
8010527b:	8b 45 08             	mov    0x8(%ebp),%eax
8010527e:	89 04 24             	mov    %eax,(%esp)
80105281:	e8 84 ff ff ff       	call   8010520a <stosl>
80105286:	eb 19                	jmp    801052a1 <memset+0x72>
  } else
    stosb(dst, c, n);
80105288:	8b 45 10             	mov    0x10(%ebp),%eax
8010528b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010528f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105292:	89 44 24 04          	mov    %eax,0x4(%esp)
80105296:	8b 45 08             	mov    0x8(%ebp),%eax
80105299:	89 04 24             	mov    %eax,(%esp)
8010529c:	e8 44 ff ff ff       	call   801051e5 <stosb>
  return dst;
801052a1:	8b 45 08             	mov    0x8(%ebp),%eax
}
801052a4:	c9                   	leave  
801052a5:	c3                   	ret    

801052a6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801052a6:	55                   	push   %ebp
801052a7:	89 e5                	mov    %esp,%ebp
801052a9:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801052ac:	8b 45 08             	mov    0x8(%ebp),%eax
801052af:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801052b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801052b8:	eb 30                	jmp    801052ea <memcmp+0x44>
    if(*s1 != *s2)
801052ba:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052bd:	0f b6 10             	movzbl (%eax),%edx
801052c0:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052c3:	0f b6 00             	movzbl (%eax),%eax
801052c6:	38 c2                	cmp    %al,%dl
801052c8:	74 18                	je     801052e2 <memcmp+0x3c>
      return *s1 - *s2;
801052ca:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052cd:	0f b6 00             	movzbl (%eax),%eax
801052d0:	0f b6 d0             	movzbl %al,%edx
801052d3:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052d6:	0f b6 00             	movzbl (%eax),%eax
801052d9:	0f b6 c0             	movzbl %al,%eax
801052dc:	29 c2                	sub    %eax,%edx
801052de:	89 d0                	mov    %edx,%eax
801052e0:	eb 1a                	jmp    801052fc <memcmp+0x56>
    s1++, s2++;
801052e2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801052e6:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801052ea:	8b 45 10             	mov    0x10(%ebp),%eax
801052ed:	8d 50 ff             	lea    -0x1(%eax),%edx
801052f0:	89 55 10             	mov    %edx,0x10(%ebp)
801052f3:	85 c0                	test   %eax,%eax
801052f5:	75 c3                	jne    801052ba <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801052f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052fc:	c9                   	leave  
801052fd:	c3                   	ret    

801052fe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801052fe:	55                   	push   %ebp
801052ff:	89 e5                	mov    %esp,%ebp
80105301:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105304:	8b 45 0c             	mov    0xc(%ebp),%eax
80105307:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010530a:	8b 45 08             	mov    0x8(%ebp),%eax
8010530d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105310:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105313:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105316:	73 3d                	jae    80105355 <memmove+0x57>
80105318:	8b 45 10             	mov    0x10(%ebp),%eax
8010531b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010531e:	01 d0                	add    %edx,%eax
80105320:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105323:	76 30                	jbe    80105355 <memmove+0x57>
    s += n;
80105325:	8b 45 10             	mov    0x10(%ebp),%eax
80105328:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010532b:	8b 45 10             	mov    0x10(%ebp),%eax
8010532e:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105331:	eb 13                	jmp    80105346 <memmove+0x48>
      *--d = *--s;
80105333:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105337:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010533b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010533e:	0f b6 10             	movzbl (%eax),%edx
80105341:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105344:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105346:	8b 45 10             	mov    0x10(%ebp),%eax
80105349:	8d 50 ff             	lea    -0x1(%eax),%edx
8010534c:	89 55 10             	mov    %edx,0x10(%ebp)
8010534f:	85 c0                	test   %eax,%eax
80105351:	75 e0                	jne    80105333 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105353:	eb 26                	jmp    8010537b <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105355:	eb 17                	jmp    8010536e <memmove+0x70>
      *d++ = *s++;
80105357:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010535a:	8d 50 01             	lea    0x1(%eax),%edx
8010535d:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105360:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105363:	8d 4a 01             	lea    0x1(%edx),%ecx
80105366:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105369:	0f b6 12             	movzbl (%edx),%edx
8010536c:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010536e:	8b 45 10             	mov    0x10(%ebp),%eax
80105371:	8d 50 ff             	lea    -0x1(%eax),%edx
80105374:	89 55 10             	mov    %edx,0x10(%ebp)
80105377:	85 c0                	test   %eax,%eax
80105379:	75 dc                	jne    80105357 <memmove+0x59>
      *d++ = *s++;

  return dst;
8010537b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010537e:	c9                   	leave  
8010537f:	c3                   	ret    

80105380 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105380:	55                   	push   %ebp
80105381:	89 e5                	mov    %esp,%ebp
80105383:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105386:	8b 45 10             	mov    0x10(%ebp),%eax
80105389:	89 44 24 08          	mov    %eax,0x8(%esp)
8010538d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105390:	89 44 24 04          	mov    %eax,0x4(%esp)
80105394:	8b 45 08             	mov    0x8(%ebp),%eax
80105397:	89 04 24             	mov    %eax,(%esp)
8010539a:	e8 5f ff ff ff       	call   801052fe <memmove>
}
8010539f:	c9                   	leave  
801053a0:	c3                   	ret    

801053a1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801053a1:	55                   	push   %ebp
801053a2:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801053a4:	eb 0c                	jmp    801053b2 <strncmp+0x11>
    n--, p++, q++;
801053a6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053aa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801053ae:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801053b2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053b6:	74 1a                	je     801053d2 <strncmp+0x31>
801053b8:	8b 45 08             	mov    0x8(%ebp),%eax
801053bb:	0f b6 00             	movzbl (%eax),%eax
801053be:	84 c0                	test   %al,%al
801053c0:	74 10                	je     801053d2 <strncmp+0x31>
801053c2:	8b 45 08             	mov    0x8(%ebp),%eax
801053c5:	0f b6 10             	movzbl (%eax),%edx
801053c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801053cb:	0f b6 00             	movzbl (%eax),%eax
801053ce:	38 c2                	cmp    %al,%dl
801053d0:	74 d4                	je     801053a6 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801053d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053d6:	75 07                	jne    801053df <strncmp+0x3e>
    return 0;
801053d8:	b8 00 00 00 00       	mov    $0x0,%eax
801053dd:	eb 16                	jmp    801053f5 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
801053df:	8b 45 08             	mov    0x8(%ebp),%eax
801053e2:	0f b6 00             	movzbl (%eax),%eax
801053e5:	0f b6 d0             	movzbl %al,%edx
801053e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801053eb:	0f b6 00             	movzbl (%eax),%eax
801053ee:	0f b6 c0             	movzbl %al,%eax
801053f1:	29 c2                	sub    %eax,%edx
801053f3:	89 d0                	mov    %edx,%eax
}
801053f5:	5d                   	pop    %ebp
801053f6:	c3                   	ret    

801053f7 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801053f7:	55                   	push   %ebp
801053f8:	89 e5                	mov    %esp,%ebp
801053fa:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801053fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105400:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105403:	90                   	nop
80105404:	8b 45 10             	mov    0x10(%ebp),%eax
80105407:	8d 50 ff             	lea    -0x1(%eax),%edx
8010540a:	89 55 10             	mov    %edx,0x10(%ebp)
8010540d:	85 c0                	test   %eax,%eax
8010540f:	7e 1e                	jle    8010542f <strncpy+0x38>
80105411:	8b 45 08             	mov    0x8(%ebp),%eax
80105414:	8d 50 01             	lea    0x1(%eax),%edx
80105417:	89 55 08             	mov    %edx,0x8(%ebp)
8010541a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010541d:	8d 4a 01             	lea    0x1(%edx),%ecx
80105420:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105423:	0f b6 12             	movzbl (%edx),%edx
80105426:	88 10                	mov    %dl,(%eax)
80105428:	0f b6 00             	movzbl (%eax),%eax
8010542b:	84 c0                	test   %al,%al
8010542d:	75 d5                	jne    80105404 <strncpy+0xd>
    ;
  while(n-- > 0)
8010542f:	eb 0c                	jmp    8010543d <strncpy+0x46>
    *s++ = 0;
80105431:	8b 45 08             	mov    0x8(%ebp),%eax
80105434:	8d 50 01             	lea    0x1(%eax),%edx
80105437:	89 55 08             	mov    %edx,0x8(%ebp)
8010543a:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010543d:	8b 45 10             	mov    0x10(%ebp),%eax
80105440:	8d 50 ff             	lea    -0x1(%eax),%edx
80105443:	89 55 10             	mov    %edx,0x10(%ebp)
80105446:	85 c0                	test   %eax,%eax
80105448:	7f e7                	jg     80105431 <strncpy+0x3a>
    *s++ = 0;
  return os;
8010544a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010544d:	c9                   	leave  
8010544e:	c3                   	ret    

8010544f <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010544f:	55                   	push   %ebp
80105450:	89 e5                	mov    %esp,%ebp
80105452:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105455:	8b 45 08             	mov    0x8(%ebp),%eax
80105458:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010545b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010545f:	7f 05                	jg     80105466 <safestrcpy+0x17>
    return os;
80105461:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105464:	eb 31                	jmp    80105497 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105466:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010546a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010546e:	7e 1e                	jle    8010548e <safestrcpy+0x3f>
80105470:	8b 45 08             	mov    0x8(%ebp),%eax
80105473:	8d 50 01             	lea    0x1(%eax),%edx
80105476:	89 55 08             	mov    %edx,0x8(%ebp)
80105479:	8b 55 0c             	mov    0xc(%ebp),%edx
8010547c:	8d 4a 01             	lea    0x1(%edx),%ecx
8010547f:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105482:	0f b6 12             	movzbl (%edx),%edx
80105485:	88 10                	mov    %dl,(%eax)
80105487:	0f b6 00             	movzbl (%eax),%eax
8010548a:	84 c0                	test   %al,%al
8010548c:	75 d8                	jne    80105466 <safestrcpy+0x17>
    ;
  *s = 0;
8010548e:	8b 45 08             	mov    0x8(%ebp),%eax
80105491:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105494:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105497:	c9                   	leave  
80105498:	c3                   	ret    

80105499 <strlen>:

int
strlen(const char *s)
{
80105499:	55                   	push   %ebp
8010549a:	89 e5                	mov    %esp,%ebp
8010549c:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010549f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801054a6:	eb 04                	jmp    801054ac <strlen+0x13>
801054a8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054ac:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054af:	8b 45 08             	mov    0x8(%ebp),%eax
801054b2:	01 d0                	add    %edx,%eax
801054b4:	0f b6 00             	movzbl (%eax),%eax
801054b7:	84 c0                	test   %al,%al
801054b9:	75 ed                	jne    801054a8 <strlen+0xf>
    ;
  return n;
801054bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801054be:	c9                   	leave  
801054bf:	c3                   	ret    

801054c0 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801054c0:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801054c4:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801054c8:	55                   	push   %ebp
  pushl %ebx
801054c9:	53                   	push   %ebx
  pushl %esi
801054ca:	56                   	push   %esi
  pushl %edi
801054cb:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801054cc:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801054ce:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801054d0:	5f                   	pop    %edi
  popl %esi
801054d1:	5e                   	pop    %esi
  popl %ebx
801054d2:	5b                   	pop    %ebx
  popl %ebp
801054d3:	5d                   	pop    %ebp
  ret
801054d4:	c3                   	ret    

801054d5 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801054d5:	55                   	push   %ebp
801054d6:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
801054d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054de:	8b 00                	mov    (%eax),%eax
801054e0:	3b 45 08             	cmp    0x8(%ebp),%eax
801054e3:	76 12                	jbe    801054f7 <fetchint+0x22>
801054e5:	8b 45 08             	mov    0x8(%ebp),%eax
801054e8:	8d 50 04             	lea    0x4(%eax),%edx
801054eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054f1:	8b 00                	mov    (%eax),%eax
801054f3:	39 c2                	cmp    %eax,%edx
801054f5:	76 07                	jbe    801054fe <fetchint+0x29>
    return -1;
801054f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054fc:	eb 0f                	jmp    8010550d <fetchint+0x38>
  *ip = *(int*)(addr);
801054fe:	8b 45 08             	mov    0x8(%ebp),%eax
80105501:	8b 10                	mov    (%eax),%edx
80105503:	8b 45 0c             	mov    0xc(%ebp),%eax
80105506:	89 10                	mov    %edx,(%eax)
  return 0;
80105508:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010550d:	5d                   	pop    %ebp
8010550e:	c3                   	ret    

8010550f <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010550f:	55                   	push   %ebp
80105510:	89 e5                	mov    %esp,%ebp
80105512:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105515:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010551b:	8b 00                	mov    (%eax),%eax
8010551d:	3b 45 08             	cmp    0x8(%ebp),%eax
80105520:	77 07                	ja     80105529 <fetchstr+0x1a>
    return -1;
80105522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105527:	eb 46                	jmp    8010556f <fetchstr+0x60>
  *pp = (char*)addr;
80105529:	8b 55 08             	mov    0x8(%ebp),%edx
8010552c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010552f:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105531:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105537:	8b 00                	mov    (%eax),%eax
80105539:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010553c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010553f:	8b 00                	mov    (%eax),%eax
80105541:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105544:	eb 1c                	jmp    80105562 <fetchstr+0x53>
    if(*s == 0)
80105546:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105549:	0f b6 00             	movzbl (%eax),%eax
8010554c:	84 c0                	test   %al,%al
8010554e:	75 0e                	jne    8010555e <fetchstr+0x4f>
      return s - *pp;
80105550:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105553:	8b 45 0c             	mov    0xc(%ebp),%eax
80105556:	8b 00                	mov    (%eax),%eax
80105558:	29 c2                	sub    %eax,%edx
8010555a:	89 d0                	mov    %edx,%eax
8010555c:	eb 11                	jmp    8010556f <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
8010555e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105562:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105565:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105568:	72 dc                	jb     80105546 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
8010556a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010556f:	c9                   	leave  
80105570:	c3                   	ret    

80105571 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105571:	55                   	push   %ebp
80105572:	89 e5                	mov    %esp,%ebp
80105574:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105577:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010557d:	8b 40 18             	mov    0x18(%eax),%eax
80105580:	8b 50 44             	mov    0x44(%eax),%edx
80105583:	8b 45 08             	mov    0x8(%ebp),%eax
80105586:	c1 e0 02             	shl    $0x2,%eax
80105589:	01 d0                	add    %edx,%eax
8010558b:	8d 50 04             	lea    0x4(%eax),%edx
8010558e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105591:	89 44 24 04          	mov    %eax,0x4(%esp)
80105595:	89 14 24             	mov    %edx,(%esp)
80105598:	e8 38 ff ff ff       	call   801054d5 <fetchint>
}
8010559d:	c9                   	leave  
8010559e:	c3                   	ret    

8010559f <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010559f:	55                   	push   %ebp
801055a0:	89 e5                	mov    %esp,%ebp
801055a2:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801055a5:	8d 45 fc             	lea    -0x4(%ebp),%eax
801055a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ac:	8b 45 08             	mov    0x8(%ebp),%eax
801055af:	89 04 24             	mov    %eax,(%esp)
801055b2:	e8 ba ff ff ff       	call   80105571 <argint>
801055b7:	85 c0                	test   %eax,%eax
801055b9:	79 07                	jns    801055c2 <argptr+0x23>
    return -1;
801055bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055c0:	eb 3d                	jmp    801055ff <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801055c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055c5:	89 c2                	mov    %eax,%edx
801055c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055cd:	8b 00                	mov    (%eax),%eax
801055cf:	39 c2                	cmp    %eax,%edx
801055d1:	73 16                	jae    801055e9 <argptr+0x4a>
801055d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055d6:	89 c2                	mov    %eax,%edx
801055d8:	8b 45 10             	mov    0x10(%ebp),%eax
801055db:	01 c2                	add    %eax,%edx
801055dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055e3:	8b 00                	mov    (%eax),%eax
801055e5:	39 c2                	cmp    %eax,%edx
801055e7:	76 07                	jbe    801055f0 <argptr+0x51>
    return -1;
801055e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055ee:	eb 0f                	jmp    801055ff <argptr+0x60>
  *pp = (char*)i;
801055f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055f3:	89 c2                	mov    %eax,%edx
801055f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801055f8:	89 10                	mov    %edx,(%eax)
  return 0;
801055fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055ff:	c9                   	leave  
80105600:	c3                   	ret    

80105601 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105601:	55                   	push   %ebp
80105602:	89 e5                	mov    %esp,%ebp
80105604:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105607:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010560a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010560e:	8b 45 08             	mov    0x8(%ebp),%eax
80105611:	89 04 24             	mov    %eax,(%esp)
80105614:	e8 58 ff ff ff       	call   80105571 <argint>
80105619:	85 c0                	test   %eax,%eax
8010561b:	79 07                	jns    80105624 <argstr+0x23>
    return -1;
8010561d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105622:	eb 12                	jmp    80105636 <argstr+0x35>
  return fetchstr(addr, pp);
80105624:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105627:	8b 55 0c             	mov    0xc(%ebp),%edx
8010562a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010562e:	89 04 24             	mov    %eax,(%esp)
80105631:	e8 d9 fe ff ff       	call   8010550f <fetchstr>
}
80105636:	c9                   	leave  
80105637:	c3                   	ret    

80105638 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105638:	55                   	push   %ebp
80105639:	89 e5                	mov    %esp,%ebp
8010563b:	53                   	push   %ebx
8010563c:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010563f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105645:	8b 40 18             	mov    0x18(%eax),%eax
80105648:	8b 40 1c             	mov    0x1c(%eax),%eax
8010564b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010564e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105652:	7e 30                	jle    80105684 <syscall+0x4c>
80105654:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105657:	83 f8 15             	cmp    $0x15,%eax
8010565a:	77 28                	ja     80105684 <syscall+0x4c>
8010565c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010565f:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105666:	85 c0                	test   %eax,%eax
80105668:	74 1a                	je     80105684 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
8010566a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105670:	8b 58 18             	mov    0x18(%eax),%ebx
80105673:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105676:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010567d:	ff d0                	call   *%eax
8010567f:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105682:	eb 3d                	jmp    801056c1 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105684:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010568a:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010568d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105693:	8b 40 10             	mov    0x10(%eax),%eax
80105696:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105699:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010569d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801056a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801056a5:	c7 04 24 f3 89 10 80 	movl   $0x801089f3,(%esp)
801056ac:	e8 ef ac ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801056b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056b7:	8b 40 18             	mov    0x18(%eax),%eax
801056ba:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801056c1:	83 c4 24             	add    $0x24,%esp
801056c4:	5b                   	pop    %ebx
801056c5:	5d                   	pop    %ebp
801056c6:	c3                   	ret    

801056c7 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801056c7:	55                   	push   %ebp
801056c8:	89 e5                	mov    %esp,%ebp
801056ca:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801056cd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d4:	8b 45 08             	mov    0x8(%ebp),%eax
801056d7:	89 04 24             	mov    %eax,(%esp)
801056da:	e8 92 fe ff ff       	call   80105571 <argint>
801056df:	85 c0                	test   %eax,%eax
801056e1:	79 07                	jns    801056ea <argfd+0x23>
    return -1;
801056e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056e8:	eb 50                	jmp    8010573a <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801056ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056ed:	85 c0                	test   %eax,%eax
801056ef:	78 21                	js     80105712 <argfd+0x4b>
801056f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056f4:	83 f8 0f             	cmp    $0xf,%eax
801056f7:	7f 19                	jg     80105712 <argfd+0x4b>
801056f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105702:	83 c2 08             	add    $0x8,%edx
80105705:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105709:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010570c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105710:	75 07                	jne    80105719 <argfd+0x52>
    return -1;
80105712:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105717:	eb 21                	jmp    8010573a <argfd+0x73>
  if(pfd)
80105719:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010571d:	74 08                	je     80105727 <argfd+0x60>
    *pfd = fd;
8010571f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105722:	8b 45 0c             	mov    0xc(%ebp),%eax
80105725:	89 10                	mov    %edx,(%eax)
  if(pf)
80105727:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010572b:	74 08                	je     80105735 <argfd+0x6e>
    *pf = f;
8010572d:	8b 45 10             	mov    0x10(%ebp),%eax
80105730:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105733:	89 10                	mov    %edx,(%eax)
  return 0;
80105735:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010573a:	c9                   	leave  
8010573b:	c3                   	ret    

8010573c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010573c:	55                   	push   %ebp
8010573d:	89 e5                	mov    %esp,%ebp
8010573f:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105742:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105749:	eb 30                	jmp    8010577b <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
8010574b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105751:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105754:	83 c2 08             	add    $0x8,%edx
80105757:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010575b:	85 c0                	test   %eax,%eax
8010575d:	75 18                	jne    80105777 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010575f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105765:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105768:	8d 4a 08             	lea    0x8(%edx),%ecx
8010576b:	8b 55 08             	mov    0x8(%ebp),%edx
8010576e:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105772:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105775:	eb 0f                	jmp    80105786 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105777:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010577b:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010577f:	7e ca                	jle    8010574b <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105781:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105786:	c9                   	leave  
80105787:	c3                   	ret    

80105788 <sys_dup>:

int
sys_dup(void)
{
80105788:	55                   	push   %ebp
80105789:	89 e5                	mov    %esp,%ebp
8010578b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010578e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105791:	89 44 24 08          	mov    %eax,0x8(%esp)
80105795:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010579c:	00 
8010579d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057a4:	e8 1e ff ff ff       	call   801056c7 <argfd>
801057a9:	85 c0                	test   %eax,%eax
801057ab:	79 07                	jns    801057b4 <sys_dup+0x2c>
    return -1;
801057ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057b2:	eb 29                	jmp    801057dd <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801057b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057b7:	89 04 24             	mov    %eax,(%esp)
801057ba:	e8 7d ff ff ff       	call   8010573c <fdalloc>
801057bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057c2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801057c6:	79 07                	jns    801057cf <sys_dup+0x47>
    return -1;
801057c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057cd:	eb 0e                	jmp    801057dd <sys_dup+0x55>
  filedup(f);
801057cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057d2:	89 04 24             	mov    %eax,(%esp)
801057d5:	e8 c7 b7 ff ff       	call   80100fa1 <filedup>
  return fd;
801057da:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801057dd:	c9                   	leave  
801057de:	c3                   	ret    

801057df <sys_read>:

int
sys_read(void)
{
801057df:	55                   	push   %ebp
801057e0:	89 e5                	mov    %esp,%ebp
801057e2:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801057e5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057e8:	89 44 24 08          	mov    %eax,0x8(%esp)
801057ec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057f3:	00 
801057f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057fb:	e8 c7 fe ff ff       	call   801056c7 <argfd>
80105800:	85 c0                	test   %eax,%eax
80105802:	78 35                	js     80105839 <sys_read+0x5a>
80105804:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105807:	89 44 24 04          	mov    %eax,0x4(%esp)
8010580b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105812:	e8 5a fd ff ff       	call   80105571 <argint>
80105817:	85 c0                	test   %eax,%eax
80105819:	78 1e                	js     80105839 <sys_read+0x5a>
8010581b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010581e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105822:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105825:	89 44 24 04          	mov    %eax,0x4(%esp)
80105829:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105830:	e8 6a fd ff ff       	call   8010559f <argptr>
80105835:	85 c0                	test   %eax,%eax
80105837:	79 07                	jns    80105840 <sys_read+0x61>
    return -1;
80105839:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010583e:	eb 19                	jmp    80105859 <sys_read+0x7a>
  return fileread(f, p, n);
80105840:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105843:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105849:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010584d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105851:	89 04 24             	mov    %eax,(%esp)
80105854:	e8 b5 b8 ff ff       	call   8010110e <fileread>
}
80105859:	c9                   	leave  
8010585a:	c3                   	ret    

8010585b <sys_write>:

int
sys_write(void)
{
8010585b:	55                   	push   %ebp
8010585c:	89 e5                	mov    %esp,%ebp
8010585e:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105861:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105864:	89 44 24 08          	mov    %eax,0x8(%esp)
80105868:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010586f:	00 
80105870:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105877:	e8 4b fe ff ff       	call   801056c7 <argfd>
8010587c:	85 c0                	test   %eax,%eax
8010587e:	78 35                	js     801058b5 <sys_write+0x5a>
80105880:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105883:	89 44 24 04          	mov    %eax,0x4(%esp)
80105887:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010588e:	e8 de fc ff ff       	call   80105571 <argint>
80105893:	85 c0                	test   %eax,%eax
80105895:	78 1e                	js     801058b5 <sys_write+0x5a>
80105897:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010589a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010589e:	8d 45 ec             	lea    -0x14(%ebp),%eax
801058a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801058a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058ac:	e8 ee fc ff ff       	call   8010559f <argptr>
801058b1:	85 c0                	test   %eax,%eax
801058b3:	79 07                	jns    801058bc <sys_write+0x61>
    return -1;
801058b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058ba:	eb 19                	jmp    801058d5 <sys_write+0x7a>
  return filewrite(f, p, n);
801058bc:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801058bf:	8b 55 ec             	mov    -0x14(%ebp),%edx
801058c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058c5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801058c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801058cd:	89 04 24             	mov    %eax,(%esp)
801058d0:	e8 f5 b8 ff ff       	call   801011ca <filewrite>
}
801058d5:	c9                   	leave  
801058d6:	c3                   	ret    

801058d7 <sys_close>:

int
sys_close(void)
{
801058d7:	55                   	push   %ebp
801058d8:	89 e5                	mov    %esp,%ebp
801058da:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801058dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058e0:	89 44 24 08          	mov    %eax,0x8(%esp)
801058e4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801058e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801058eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058f2:	e8 d0 fd ff ff       	call   801056c7 <argfd>
801058f7:	85 c0                	test   %eax,%eax
801058f9:	79 07                	jns    80105902 <sys_close+0x2b>
    return -1;
801058fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105900:	eb 24                	jmp    80105926 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105902:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105908:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010590b:	83 c2 08             	add    $0x8,%edx
8010590e:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105915:	00 
  fileclose(f);
80105916:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105919:	89 04 24             	mov    %eax,(%esp)
8010591c:	e8 c8 b6 ff ff       	call   80100fe9 <fileclose>
  return 0;
80105921:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105926:	c9                   	leave  
80105927:	c3                   	ret    

80105928 <sys_fstat>:

int
sys_fstat(void)
{
80105928:	55                   	push   %ebp
80105929:	89 e5                	mov    %esp,%ebp
8010592b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010592e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105931:	89 44 24 08          	mov    %eax,0x8(%esp)
80105935:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010593c:	00 
8010593d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105944:	e8 7e fd ff ff       	call   801056c7 <argfd>
80105949:	85 c0                	test   %eax,%eax
8010594b:	78 1f                	js     8010596c <sys_fstat+0x44>
8010594d:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105954:	00 
80105955:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105958:	89 44 24 04          	mov    %eax,0x4(%esp)
8010595c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105963:	e8 37 fc ff ff       	call   8010559f <argptr>
80105968:	85 c0                	test   %eax,%eax
8010596a:	79 07                	jns    80105973 <sys_fstat+0x4b>
    return -1;
8010596c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105971:	eb 12                	jmp    80105985 <sys_fstat+0x5d>
  return filestat(f, st);
80105973:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105976:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105979:	89 54 24 04          	mov    %edx,0x4(%esp)
8010597d:	89 04 24             	mov    %eax,(%esp)
80105980:	e8 3a b7 ff ff       	call   801010bf <filestat>
}
80105985:	c9                   	leave  
80105986:	c3                   	ret    

80105987 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105987:	55                   	push   %ebp
80105988:	89 e5                	mov    %esp,%ebp
8010598a:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010598d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105990:	89 44 24 04          	mov    %eax,0x4(%esp)
80105994:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010599b:	e8 61 fc ff ff       	call   80105601 <argstr>
801059a0:	85 c0                	test   %eax,%eax
801059a2:	78 17                	js     801059bb <sys_link+0x34>
801059a4:	8d 45 dc             	lea    -0x24(%ebp),%eax
801059a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801059ab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801059b2:	e8 4a fc ff ff       	call   80105601 <argstr>
801059b7:	85 c0                	test   %eax,%eax
801059b9:	79 0a                	jns    801059c5 <sys_link+0x3e>
    return -1;
801059bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059c0:	e9 42 01 00 00       	jmp    80105b07 <sys_link+0x180>

  begin_op();
801059c5:	e8 29 dc ff ff       	call   801035f3 <begin_op>
  if((ip = namei(old)) == 0){
801059ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
801059cd:	89 04 24             	mov    %eax,(%esp)
801059d0:	e8 e7 cb ff ff       	call   801025bc <namei>
801059d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801059d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801059dc:	75 0f                	jne    801059ed <sys_link+0x66>
    end_op();
801059de:	e8 94 dc ff ff       	call   80103677 <end_op>
    return -1;
801059e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059e8:	e9 1a 01 00 00       	jmp    80105b07 <sys_link+0x180>
  }

  ilock(ip);
801059ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059f0:	89 04 24             	mov    %eax,(%esp)
801059f3:	e8 dc be ff ff       	call   801018d4 <ilock>
  if(ip->type == T_DIR){
801059f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059fb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059ff:	66 83 f8 01          	cmp    $0x1,%ax
80105a03:	75 1a                	jne    80105a1f <sys_link+0x98>
    iunlockput(ip);
80105a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a08:	89 04 24             	mov    %eax,(%esp)
80105a0b:	e8 4e c1 ff ff       	call   80101b5e <iunlockput>
    end_op();
80105a10:	e8 62 dc ff ff       	call   80103677 <end_op>
    return -1;
80105a15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a1a:	e9 e8 00 00 00       	jmp    80105b07 <sys_link+0x180>
  }

  ip->nlink++;
80105a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a22:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a26:	8d 50 01             	lea    0x1(%eax),%edx
80105a29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a33:	89 04 24             	mov    %eax,(%esp)
80105a36:	e8 d7 bc ff ff       	call   80101712 <iupdate>
  iunlock(ip);
80105a3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a3e:	89 04 24             	mov    %eax,(%esp)
80105a41:	e8 e2 bf ff ff       	call   80101a28 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105a46:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105a49:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105a4c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a50:	89 04 24             	mov    %eax,(%esp)
80105a53:	e8 86 cb ff ff       	call   801025de <nameiparent>
80105a58:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a5b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a5f:	75 02                	jne    80105a63 <sys_link+0xdc>
    goto bad;
80105a61:	eb 68                	jmp    80105acb <sys_link+0x144>
  ilock(dp);
80105a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a66:	89 04 24             	mov    %eax,(%esp)
80105a69:	e8 66 be ff ff       	call   801018d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a71:	8b 10                	mov    (%eax),%edx
80105a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a76:	8b 00                	mov    (%eax),%eax
80105a78:	39 c2                	cmp    %eax,%edx
80105a7a:	75 20                	jne    80105a9c <sys_link+0x115>
80105a7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a7f:	8b 40 04             	mov    0x4(%eax),%eax
80105a82:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a86:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105a89:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a90:	89 04 24             	mov    %eax,(%esp)
80105a93:	e8 64 c8 ff ff       	call   801022fc <dirlink>
80105a98:	85 c0                	test   %eax,%eax
80105a9a:	79 0d                	jns    80105aa9 <sys_link+0x122>
    iunlockput(dp);
80105a9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a9f:	89 04 24             	mov    %eax,(%esp)
80105aa2:	e8 b7 c0 ff ff       	call   80101b5e <iunlockput>
    goto bad;
80105aa7:	eb 22                	jmp    80105acb <sys_link+0x144>
  }
  iunlockput(dp);
80105aa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aac:	89 04 24             	mov    %eax,(%esp)
80105aaf:	e8 aa c0 ff ff       	call   80101b5e <iunlockput>
  iput(ip);
80105ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab7:	89 04 24             	mov    %eax,(%esp)
80105aba:	e8 ce bf ff ff       	call   80101a8d <iput>

  end_op();
80105abf:	e8 b3 db ff ff       	call   80103677 <end_op>

  return 0;
80105ac4:	b8 00 00 00 00       	mov    $0x0,%eax
80105ac9:	eb 3c                	jmp    80105b07 <sys_link+0x180>

bad:
  ilock(ip);
80105acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ace:	89 04 24             	mov    %eax,(%esp)
80105ad1:	e8 fe bd ff ff       	call   801018d4 <ilock>
  ip->nlink--;
80105ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105add:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ae3:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aea:	89 04 24             	mov    %eax,(%esp)
80105aed:	e8 20 bc ff ff       	call   80101712 <iupdate>
  iunlockput(ip);
80105af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af5:	89 04 24             	mov    %eax,(%esp)
80105af8:	e8 61 c0 ff ff       	call   80101b5e <iunlockput>
  end_op();
80105afd:	e8 75 db ff ff       	call   80103677 <end_op>
  return -1;
80105b02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105b07:	c9                   	leave  
80105b08:	c3                   	ret    

80105b09 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105b09:	55                   	push   %ebp
80105b0a:	89 e5                	mov    %esp,%ebp
80105b0c:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b0f:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105b16:	eb 4b                	jmp    80105b63 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105b18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b1b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105b22:	00 
80105b23:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b27:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105b2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b2e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b31:	89 04 24             	mov    %eax,(%esp)
80105b34:	e8 e5 c3 ff ff       	call   80101f1e <readi>
80105b39:	83 f8 10             	cmp    $0x10,%eax
80105b3c:	74 0c                	je     80105b4a <isdirempty+0x41>
      panic("isdirempty: readi");
80105b3e:	c7 04 24 0f 8a 10 80 	movl   $0x80108a0f,(%esp)
80105b45:	e8 f0 a9 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105b4a:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105b4e:	66 85 c0             	test   %ax,%ax
80105b51:	74 07                	je     80105b5a <isdirempty+0x51>
      return 0;
80105b53:	b8 00 00 00 00       	mov    $0x0,%eax
80105b58:	eb 1b                	jmp    80105b75 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5d:	83 c0 10             	add    $0x10,%eax
80105b60:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b63:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b66:	8b 45 08             	mov    0x8(%ebp),%eax
80105b69:	8b 40 18             	mov    0x18(%eax),%eax
80105b6c:	39 c2                	cmp    %eax,%edx
80105b6e:	72 a8                	jb     80105b18 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105b70:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b75:	c9                   	leave  
80105b76:	c3                   	ret    

80105b77 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105b77:	55                   	push   %ebp
80105b78:	89 e5                	mov    %esp,%ebp
80105b7a:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105b7d:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105b80:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b84:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b8b:	e8 71 fa ff ff       	call   80105601 <argstr>
80105b90:	85 c0                	test   %eax,%eax
80105b92:	79 0a                	jns    80105b9e <sys_unlink+0x27>
    return -1;
80105b94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b99:	e9 af 01 00 00       	jmp    80105d4d <sys_unlink+0x1d6>

  begin_op();
80105b9e:	e8 50 da ff ff       	call   801035f3 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105ba3:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105ba6:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105ba9:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bad:	89 04 24             	mov    %eax,(%esp)
80105bb0:	e8 29 ca ff ff       	call   801025de <nameiparent>
80105bb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bb8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bbc:	75 0f                	jne    80105bcd <sys_unlink+0x56>
    end_op();
80105bbe:	e8 b4 da ff ff       	call   80103677 <end_op>
    return -1;
80105bc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bc8:	e9 80 01 00 00       	jmp    80105d4d <sys_unlink+0x1d6>
  }

  ilock(dp);
80105bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd0:	89 04 24             	mov    %eax,(%esp)
80105bd3:	e8 fc bc ff ff       	call   801018d4 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105bd8:	c7 44 24 04 21 8a 10 	movl   $0x80108a21,0x4(%esp)
80105bdf:	80 
80105be0:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105be3:	89 04 24             	mov    %eax,(%esp)
80105be6:	e8 26 c6 ff ff       	call   80102211 <namecmp>
80105beb:	85 c0                	test   %eax,%eax
80105bed:	0f 84 45 01 00 00    	je     80105d38 <sys_unlink+0x1c1>
80105bf3:	c7 44 24 04 23 8a 10 	movl   $0x80108a23,0x4(%esp)
80105bfa:	80 
80105bfb:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105bfe:	89 04 24             	mov    %eax,(%esp)
80105c01:	e8 0b c6 ff ff       	call   80102211 <namecmp>
80105c06:	85 c0                	test   %eax,%eax
80105c08:	0f 84 2a 01 00 00    	je     80105d38 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105c0e:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105c11:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c15:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c18:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c1f:	89 04 24             	mov    %eax,(%esp)
80105c22:	e8 0c c6 ff ff       	call   80102233 <dirlookup>
80105c27:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c2a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c2e:	75 05                	jne    80105c35 <sys_unlink+0xbe>
    goto bad;
80105c30:	e9 03 01 00 00       	jmp    80105d38 <sys_unlink+0x1c1>
  ilock(ip);
80105c35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c38:	89 04 24             	mov    %eax,(%esp)
80105c3b:	e8 94 bc ff ff       	call   801018d4 <ilock>

  if(ip->nlink < 1)
80105c40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c43:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c47:	66 85 c0             	test   %ax,%ax
80105c4a:	7f 0c                	jg     80105c58 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105c4c:	c7 04 24 26 8a 10 80 	movl   $0x80108a26,(%esp)
80105c53:	e8 e2 a8 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105c58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c5b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c5f:	66 83 f8 01          	cmp    $0x1,%ax
80105c63:	75 1f                	jne    80105c84 <sys_unlink+0x10d>
80105c65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c68:	89 04 24             	mov    %eax,(%esp)
80105c6b:	e8 99 fe ff ff       	call   80105b09 <isdirempty>
80105c70:	85 c0                	test   %eax,%eax
80105c72:	75 10                	jne    80105c84 <sys_unlink+0x10d>
    iunlockput(ip);
80105c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c77:	89 04 24             	mov    %eax,(%esp)
80105c7a:	e8 df be ff ff       	call   80101b5e <iunlockput>
    goto bad;
80105c7f:	e9 b4 00 00 00       	jmp    80105d38 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105c84:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105c8b:	00 
80105c8c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c93:	00 
80105c94:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c97:	89 04 24             	mov    %eax,(%esp)
80105c9a:	e8 90 f5 ff ff       	call   8010522f <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c9f:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105ca2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105ca9:	00 
80105caa:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cae:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cb8:	89 04 24             	mov    %eax,(%esp)
80105cbb:	e8 c2 c3 ff ff       	call   80102082 <writei>
80105cc0:	83 f8 10             	cmp    $0x10,%eax
80105cc3:	74 0c                	je     80105cd1 <sys_unlink+0x15a>
    panic("unlink: writei");
80105cc5:	c7 04 24 38 8a 10 80 	movl   $0x80108a38,(%esp)
80105ccc:	e8 69 a8 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105cd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cd4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105cd8:	66 83 f8 01          	cmp    $0x1,%ax
80105cdc:	75 1c                	jne    80105cfa <sys_unlink+0x183>
    dp->nlink--;
80105cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ce5:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ceb:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105cef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf2:	89 04 24             	mov    %eax,(%esp)
80105cf5:	e8 18 ba ff ff       	call   80101712 <iupdate>
  }
  iunlockput(dp);
80105cfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cfd:	89 04 24             	mov    %eax,(%esp)
80105d00:	e8 59 be ff ff       	call   80101b5e <iunlockput>

  ip->nlink--;
80105d05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d08:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d0c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d12:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105d16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d19:	89 04 24             	mov    %eax,(%esp)
80105d1c:	e8 f1 b9 ff ff       	call   80101712 <iupdate>
  iunlockput(ip);
80105d21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d24:	89 04 24             	mov    %eax,(%esp)
80105d27:	e8 32 be ff ff       	call   80101b5e <iunlockput>

  end_op();
80105d2c:	e8 46 d9 ff ff       	call   80103677 <end_op>

  return 0;
80105d31:	b8 00 00 00 00       	mov    $0x0,%eax
80105d36:	eb 15                	jmp    80105d4d <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d3b:	89 04 24             	mov    %eax,(%esp)
80105d3e:	e8 1b be ff ff       	call   80101b5e <iunlockput>
  end_op();
80105d43:	e8 2f d9 ff ff       	call   80103677 <end_op>
  return -1;
80105d48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d4d:	c9                   	leave  
80105d4e:	c3                   	ret    

80105d4f <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105d4f:	55                   	push   %ebp
80105d50:	89 e5                	mov    %esp,%ebp
80105d52:	83 ec 48             	sub    $0x48,%esp
80105d55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105d58:	8b 55 10             	mov    0x10(%ebp),%edx
80105d5b:	8b 45 14             	mov    0x14(%ebp),%eax
80105d5e:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105d62:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105d66:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105d6a:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d71:	8b 45 08             	mov    0x8(%ebp),%eax
80105d74:	89 04 24             	mov    %eax,(%esp)
80105d77:	e8 62 c8 ff ff       	call   801025de <nameiparent>
80105d7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d7f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d83:	75 0a                	jne    80105d8f <create+0x40>
    return 0;
80105d85:	b8 00 00 00 00       	mov    $0x0,%eax
80105d8a:	e9 7e 01 00 00       	jmp    80105f0d <create+0x1be>
  ilock(dp);
80105d8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d92:	89 04 24             	mov    %eax,(%esp)
80105d95:	e8 3a bb ff ff       	call   801018d4 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105d9a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d9d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105da1:	8d 45 de             	lea    -0x22(%ebp),%eax
80105da4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dab:	89 04 24             	mov    %eax,(%esp)
80105dae:	e8 80 c4 ff ff       	call   80102233 <dirlookup>
80105db3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105db6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105dba:	74 47                	je     80105e03 <create+0xb4>
    iunlockput(dp);
80105dbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dbf:	89 04 24             	mov    %eax,(%esp)
80105dc2:	e8 97 bd ff ff       	call   80101b5e <iunlockput>
    ilock(ip);
80105dc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dca:	89 04 24             	mov    %eax,(%esp)
80105dcd:	e8 02 bb ff ff       	call   801018d4 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105dd2:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105dd7:	75 15                	jne    80105dee <create+0x9f>
80105dd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ddc:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105de0:	66 83 f8 02          	cmp    $0x2,%ax
80105de4:	75 08                	jne    80105dee <create+0x9f>
      return ip;
80105de6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de9:	e9 1f 01 00 00       	jmp    80105f0d <create+0x1be>
    iunlockput(ip);
80105dee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df1:	89 04 24             	mov    %eax,(%esp)
80105df4:	e8 65 bd ff ff       	call   80101b5e <iunlockput>
    return 0;
80105df9:	b8 00 00 00 00       	mov    $0x0,%eax
80105dfe:	e9 0a 01 00 00       	jmp    80105f0d <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105e03:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105e07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0a:	8b 00                	mov    (%eax),%eax
80105e0c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e10:	89 04 24             	mov    %eax,(%esp)
80105e13:	e8 25 b8 ff ff       	call   8010163d <ialloc>
80105e18:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e1b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e1f:	75 0c                	jne    80105e2d <create+0xde>
    panic("create: ialloc");
80105e21:	c7 04 24 47 8a 10 80 	movl   $0x80108a47,(%esp)
80105e28:	e8 0d a7 ff ff       	call   8010053a <panic>

  ilock(ip);
80105e2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e30:	89 04 24             	mov    %eax,(%esp)
80105e33:	e8 9c ba ff ff       	call   801018d4 <ilock>
  ip->major = major;
80105e38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e3b:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105e3f:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105e43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e46:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105e4a:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105e4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e51:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105e57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e5a:	89 04 24             	mov    %eax,(%esp)
80105e5d:	e8 b0 b8 ff ff       	call   80101712 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105e62:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105e67:	75 6a                	jne    80105ed3 <create+0x184>
    dp->nlink++;  // for ".."
80105e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e6c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e70:	8d 50 01             	lea    0x1(%eax),%edx
80105e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e76:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e7d:	89 04 24             	mov    %eax,(%esp)
80105e80:	e8 8d b8 ff ff       	call   80101712 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105e85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e88:	8b 40 04             	mov    0x4(%eax),%eax
80105e8b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e8f:	c7 44 24 04 21 8a 10 	movl   $0x80108a21,0x4(%esp)
80105e96:	80 
80105e97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e9a:	89 04 24             	mov    %eax,(%esp)
80105e9d:	e8 5a c4 ff ff       	call   801022fc <dirlink>
80105ea2:	85 c0                	test   %eax,%eax
80105ea4:	78 21                	js     80105ec7 <create+0x178>
80105ea6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea9:	8b 40 04             	mov    0x4(%eax),%eax
80105eac:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eb0:	c7 44 24 04 23 8a 10 	movl   $0x80108a23,0x4(%esp)
80105eb7:	80 
80105eb8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ebb:	89 04 24             	mov    %eax,(%esp)
80105ebe:	e8 39 c4 ff ff       	call   801022fc <dirlink>
80105ec3:	85 c0                	test   %eax,%eax
80105ec5:	79 0c                	jns    80105ed3 <create+0x184>
      panic("create dots");
80105ec7:	c7 04 24 56 8a 10 80 	movl   $0x80108a56,(%esp)
80105ece:	e8 67 a6 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105ed3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed6:	8b 40 04             	mov    0x4(%eax),%eax
80105ed9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105edd:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ee0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ee7:	89 04 24             	mov    %eax,(%esp)
80105eea:	e8 0d c4 ff ff       	call   801022fc <dirlink>
80105eef:	85 c0                	test   %eax,%eax
80105ef1:	79 0c                	jns    80105eff <create+0x1b0>
    panic("create: dirlink");
80105ef3:	c7 04 24 62 8a 10 80 	movl   $0x80108a62,(%esp)
80105efa:	e8 3b a6 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80105eff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f02:	89 04 24             	mov    %eax,(%esp)
80105f05:	e8 54 bc ff ff       	call   80101b5e <iunlockput>

  return ip;
80105f0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105f0d:	c9                   	leave  
80105f0e:	c3                   	ret    

80105f0f <sys_open>:

int
sys_open(void)
{
80105f0f:	55                   	push   %ebp
80105f10:	89 e5                	mov    %esp,%ebp
80105f12:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105f15:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105f18:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f23:	e8 d9 f6 ff ff       	call   80105601 <argstr>
80105f28:	85 c0                	test   %eax,%eax
80105f2a:	78 17                	js     80105f43 <sys_open+0x34>
80105f2c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105f2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f33:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f3a:	e8 32 f6 ff ff       	call   80105571 <argint>
80105f3f:	85 c0                	test   %eax,%eax
80105f41:	79 0a                	jns    80105f4d <sys_open+0x3e>
    return -1;
80105f43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f48:	e9 5c 01 00 00       	jmp    801060a9 <sys_open+0x19a>

  begin_op();
80105f4d:	e8 a1 d6 ff ff       	call   801035f3 <begin_op>

  if(omode & O_CREATE){
80105f52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f55:	25 00 02 00 00       	and    $0x200,%eax
80105f5a:	85 c0                	test   %eax,%eax
80105f5c:	74 3b                	je     80105f99 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105f5e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f61:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105f68:	00 
80105f69:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105f70:	00 
80105f71:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105f78:	00 
80105f79:	89 04 24             	mov    %eax,(%esp)
80105f7c:	e8 ce fd ff ff       	call   80105d4f <create>
80105f81:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105f84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f88:	75 6b                	jne    80105ff5 <sys_open+0xe6>
      end_op();
80105f8a:	e8 e8 d6 ff ff       	call   80103677 <end_op>
      return -1;
80105f8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f94:	e9 10 01 00 00       	jmp    801060a9 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80105f99:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f9c:	89 04 24             	mov    %eax,(%esp)
80105f9f:	e8 18 c6 ff ff       	call   801025bc <namei>
80105fa4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fa7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fab:	75 0f                	jne    80105fbc <sys_open+0xad>
      end_op();
80105fad:	e8 c5 d6 ff ff       	call   80103677 <end_op>
      return -1;
80105fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fb7:	e9 ed 00 00 00       	jmp    801060a9 <sys_open+0x19a>
    }
    ilock(ip);
80105fbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fbf:	89 04 24             	mov    %eax,(%esp)
80105fc2:	e8 0d b9 ff ff       	call   801018d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105fc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fca:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105fce:	66 83 f8 01          	cmp    $0x1,%ax
80105fd2:	75 21                	jne    80105ff5 <sys_open+0xe6>
80105fd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fd7:	85 c0                	test   %eax,%eax
80105fd9:	74 1a                	je     80105ff5 <sys_open+0xe6>
      iunlockput(ip);
80105fdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fde:	89 04 24             	mov    %eax,(%esp)
80105fe1:	e8 78 bb ff ff       	call   80101b5e <iunlockput>
      end_op();
80105fe6:	e8 8c d6 ff ff       	call   80103677 <end_op>
      return -1;
80105feb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ff0:	e9 b4 00 00 00       	jmp    801060a9 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105ff5:	e8 47 af ff ff       	call   80100f41 <filealloc>
80105ffa:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ffd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106001:	74 14                	je     80106017 <sys_open+0x108>
80106003:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106006:	89 04 24             	mov    %eax,(%esp)
80106009:	e8 2e f7 ff ff       	call   8010573c <fdalloc>
8010600e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106011:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106015:	79 28                	jns    8010603f <sys_open+0x130>
    if(f)
80106017:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010601b:	74 0b                	je     80106028 <sys_open+0x119>
      fileclose(f);
8010601d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106020:	89 04 24             	mov    %eax,(%esp)
80106023:	e8 c1 af ff ff       	call   80100fe9 <fileclose>
    iunlockput(ip);
80106028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602b:	89 04 24             	mov    %eax,(%esp)
8010602e:	e8 2b bb ff ff       	call   80101b5e <iunlockput>
    end_op();
80106033:	e8 3f d6 ff ff       	call   80103677 <end_op>
    return -1;
80106038:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010603d:	eb 6a                	jmp    801060a9 <sys_open+0x19a>
  }
  iunlock(ip);
8010603f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106042:	89 04 24             	mov    %eax,(%esp)
80106045:	e8 de b9 ff ff       	call   80101a28 <iunlock>
  end_op();
8010604a:	e8 28 d6 ff ff       	call   80103677 <end_op>

  f->type = FD_INODE;
8010604f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106052:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106058:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010605b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010605e:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106061:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106064:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010606b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010606e:	83 e0 01             	and    $0x1,%eax
80106071:	85 c0                	test   %eax,%eax
80106073:	0f 94 c0             	sete   %al
80106076:	89 c2                	mov    %eax,%edx
80106078:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607b:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010607e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106081:	83 e0 01             	and    $0x1,%eax
80106084:	85 c0                	test   %eax,%eax
80106086:	75 0a                	jne    80106092 <sys_open+0x183>
80106088:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010608b:	83 e0 02             	and    $0x2,%eax
8010608e:	85 c0                	test   %eax,%eax
80106090:	74 07                	je     80106099 <sys_open+0x18a>
80106092:	b8 01 00 00 00       	mov    $0x1,%eax
80106097:	eb 05                	jmp    8010609e <sys_open+0x18f>
80106099:	b8 00 00 00 00       	mov    $0x0,%eax
8010609e:	89 c2                	mov    %eax,%edx
801060a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060a3:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
801060a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801060a9:	c9                   	leave  
801060aa:	c3                   	ret    

801060ab <sys_mkdir>:

int
sys_mkdir(void)
{
801060ab:	55                   	push   %ebp
801060ac:	89 e5                	mov    %esp,%ebp
801060ae:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801060b1:	e8 3d d5 ff ff       	call   801035f3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801060b6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801060bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060c4:	e8 38 f5 ff ff       	call   80105601 <argstr>
801060c9:	85 c0                	test   %eax,%eax
801060cb:	78 2c                	js     801060f9 <sys_mkdir+0x4e>
801060cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060d0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801060d7:	00 
801060d8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801060df:	00 
801060e0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801060e7:	00 
801060e8:	89 04 24             	mov    %eax,(%esp)
801060eb:	e8 5f fc ff ff       	call   80105d4f <create>
801060f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060f3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060f7:	75 0c                	jne    80106105 <sys_mkdir+0x5a>
    end_op();
801060f9:	e8 79 d5 ff ff       	call   80103677 <end_op>
    return -1;
801060fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106103:	eb 15                	jmp    8010611a <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106108:	89 04 24             	mov    %eax,(%esp)
8010610b:	e8 4e ba ff ff       	call   80101b5e <iunlockput>
  end_op();
80106110:	e8 62 d5 ff ff       	call   80103677 <end_op>
  return 0;
80106115:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010611a:	c9                   	leave  
8010611b:	c3                   	ret    

8010611c <sys_mknod>:

int
sys_mknod(void)
{
8010611c:	55                   	push   %ebp
8010611d:	89 e5                	mov    %esp,%ebp
8010611f:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106122:	e8 cc d4 ff ff       	call   801035f3 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106127:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010612a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010612e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106135:	e8 c7 f4 ff ff       	call   80105601 <argstr>
8010613a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010613d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106141:	78 5e                	js     801061a1 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106143:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106146:	89 44 24 04          	mov    %eax,0x4(%esp)
8010614a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106151:	e8 1b f4 ff ff       	call   80105571 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106156:	85 c0                	test   %eax,%eax
80106158:	78 47                	js     801061a1 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010615a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010615d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106161:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106168:	e8 04 f4 ff ff       	call   80105571 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010616d:	85 c0                	test   %eax,%eax
8010616f:	78 30                	js     801061a1 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106171:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106174:	0f bf c8             	movswl %ax,%ecx
80106177:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010617a:	0f bf d0             	movswl %ax,%edx
8010617d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106180:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106184:	89 54 24 08          	mov    %edx,0x8(%esp)
80106188:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010618f:	00 
80106190:	89 04 24             	mov    %eax,(%esp)
80106193:	e8 b7 fb ff ff       	call   80105d4f <create>
80106198:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010619b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010619f:	75 0c                	jne    801061ad <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801061a1:	e8 d1 d4 ff ff       	call   80103677 <end_op>
    return -1;
801061a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ab:	eb 15                	jmp    801061c2 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801061ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b0:	89 04 24             	mov    %eax,(%esp)
801061b3:	e8 a6 b9 ff ff       	call   80101b5e <iunlockput>
  end_op();
801061b8:	e8 ba d4 ff ff       	call   80103677 <end_op>
  return 0;
801061bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061c2:	c9                   	leave  
801061c3:	c3                   	ret    

801061c4 <sys_chdir>:

int
sys_chdir(void)
{
801061c4:	55                   	push   %ebp
801061c5:	89 e5                	mov    %esp,%ebp
801061c7:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801061ca:	e8 24 d4 ff ff       	call   801035f3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801061cf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801061d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061dd:	e8 1f f4 ff ff       	call   80105601 <argstr>
801061e2:	85 c0                	test   %eax,%eax
801061e4:	78 14                	js     801061fa <sys_chdir+0x36>
801061e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061e9:	89 04 24             	mov    %eax,(%esp)
801061ec:	e8 cb c3 ff ff       	call   801025bc <namei>
801061f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061f8:	75 0c                	jne    80106206 <sys_chdir+0x42>
    end_op();
801061fa:	e8 78 d4 ff ff       	call   80103677 <end_op>
    return -1;
801061ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106204:	eb 61                	jmp    80106267 <sys_chdir+0xa3>
  }
  ilock(ip);
80106206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106209:	89 04 24             	mov    %eax,(%esp)
8010620c:	e8 c3 b6 ff ff       	call   801018d4 <ilock>
  if(ip->type != T_DIR){
80106211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106214:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106218:	66 83 f8 01          	cmp    $0x1,%ax
8010621c:	74 17                	je     80106235 <sys_chdir+0x71>
    iunlockput(ip);
8010621e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106221:	89 04 24             	mov    %eax,(%esp)
80106224:	e8 35 b9 ff ff       	call   80101b5e <iunlockput>
    end_op();
80106229:	e8 49 d4 ff ff       	call   80103677 <end_op>
    return -1;
8010622e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106233:	eb 32                	jmp    80106267 <sys_chdir+0xa3>
  }
  iunlock(ip);
80106235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106238:	89 04 24             	mov    %eax,(%esp)
8010623b:	e8 e8 b7 ff ff       	call   80101a28 <iunlock>
  iput(proc->cwd);
80106240:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106246:	8b 40 68             	mov    0x68(%eax),%eax
80106249:	89 04 24             	mov    %eax,(%esp)
8010624c:	e8 3c b8 ff ff       	call   80101a8d <iput>
  end_op();
80106251:	e8 21 d4 ff ff       	call   80103677 <end_op>
  proc->cwd = ip;
80106256:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010625c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010625f:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106262:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106267:	c9                   	leave  
80106268:	c3                   	ret    

80106269 <sys_exec>:

int
sys_exec(void)
{
80106269:	55                   	push   %ebp
8010626a:	89 e5                	mov    %esp,%ebp
8010626c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106272:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106275:	89 44 24 04          	mov    %eax,0x4(%esp)
80106279:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106280:	e8 7c f3 ff ff       	call   80105601 <argstr>
80106285:	85 c0                	test   %eax,%eax
80106287:	78 1a                	js     801062a3 <sys_exec+0x3a>
80106289:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010628f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106293:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010629a:	e8 d2 f2 ff ff       	call   80105571 <argint>
8010629f:	85 c0                	test   %eax,%eax
801062a1:	79 0a                	jns    801062ad <sys_exec+0x44>
    return -1;
801062a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062a8:	e9 c8 00 00 00       	jmp    80106375 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
801062ad:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801062b4:	00 
801062b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062bc:	00 
801062bd:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062c3:	89 04 24             	mov    %eax,(%esp)
801062c6:	e8 64 ef ff ff       	call   8010522f <memset>
  for(i=0;; i++){
801062cb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801062d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d5:	83 f8 1f             	cmp    $0x1f,%eax
801062d8:	76 0a                	jbe    801062e4 <sys_exec+0x7b>
      return -1;
801062da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062df:	e9 91 00 00 00       	jmp    80106375 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
801062e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062e7:	c1 e0 02             	shl    $0x2,%eax
801062ea:	89 c2                	mov    %eax,%edx
801062ec:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801062f2:	01 c2                	add    %eax,%edx
801062f4:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
801062fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801062fe:	89 14 24             	mov    %edx,(%esp)
80106301:	e8 cf f1 ff ff       	call   801054d5 <fetchint>
80106306:	85 c0                	test   %eax,%eax
80106308:	79 07                	jns    80106311 <sys_exec+0xa8>
      return -1;
8010630a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010630f:	eb 64                	jmp    80106375 <sys_exec+0x10c>
    if(uarg == 0){
80106311:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106317:	85 c0                	test   %eax,%eax
80106319:	75 26                	jne    80106341 <sys_exec+0xd8>
      argv[i] = 0;
8010631b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010631e:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106325:	00 00 00 00 
      break;
80106329:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
8010632a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010632d:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106333:	89 54 24 04          	mov    %edx,0x4(%esp)
80106337:	89 04 24             	mov    %eax,(%esp)
8010633a:	e8 cb a7 ff ff       	call   80100b0a <exec>
8010633f:	eb 34                	jmp    80106375 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106341:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106347:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010634a:	c1 e2 02             	shl    $0x2,%edx
8010634d:	01 c2                	add    %eax,%edx
8010634f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106355:	89 54 24 04          	mov    %edx,0x4(%esp)
80106359:	89 04 24             	mov    %eax,(%esp)
8010635c:	e8 ae f1 ff ff       	call   8010550f <fetchstr>
80106361:	85 c0                	test   %eax,%eax
80106363:	79 07                	jns    8010636c <sys_exec+0x103>
      return -1;
80106365:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010636a:	eb 09                	jmp    80106375 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010636c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106370:	e9 5d ff ff ff       	jmp    801062d2 <sys_exec+0x69>
  return exec(path, argv);
}
80106375:	c9                   	leave  
80106376:	c3                   	ret    

80106377 <sys_pipe>:

int
sys_pipe(void)
{
80106377:	55                   	push   %ebp
80106378:	89 e5                	mov    %esp,%ebp
8010637a:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010637d:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106384:	00 
80106385:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106388:	89 44 24 04          	mov    %eax,0x4(%esp)
8010638c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106393:	e8 07 f2 ff ff       	call   8010559f <argptr>
80106398:	85 c0                	test   %eax,%eax
8010639a:	79 0a                	jns    801063a6 <sys_pipe+0x2f>
    return -1;
8010639c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063a1:	e9 9b 00 00 00       	jmp    80106441 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801063a6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801063ad:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063b0:	89 04 24             	mov    %eax,(%esp)
801063b3:	e8 47 dd ff ff       	call   801040ff <pipealloc>
801063b8:	85 c0                	test   %eax,%eax
801063ba:	79 07                	jns    801063c3 <sys_pipe+0x4c>
    return -1;
801063bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063c1:	eb 7e                	jmp    80106441 <sys_pipe+0xca>
  fd0 = -1;
801063c3:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801063ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063cd:	89 04 24             	mov    %eax,(%esp)
801063d0:	e8 67 f3 ff ff       	call   8010573c <fdalloc>
801063d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063dc:	78 14                	js     801063f2 <sys_pipe+0x7b>
801063de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063e1:	89 04 24             	mov    %eax,(%esp)
801063e4:	e8 53 f3 ff ff       	call   8010573c <fdalloc>
801063e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801063ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801063f0:	79 37                	jns    80106429 <sys_pipe+0xb2>
    if(fd0 >= 0)
801063f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063f6:	78 14                	js     8010640c <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801063f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106401:	83 c2 08             	add    $0x8,%edx
80106404:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010640b:	00 
    fileclose(rf);
8010640c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010640f:	89 04 24             	mov    %eax,(%esp)
80106412:	e8 d2 ab ff ff       	call   80100fe9 <fileclose>
    fileclose(wf);
80106417:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010641a:	89 04 24             	mov    %eax,(%esp)
8010641d:	e8 c7 ab ff ff       	call   80100fe9 <fileclose>
    return -1;
80106422:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106427:	eb 18                	jmp    80106441 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106429:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010642c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010642f:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106431:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106434:	8d 50 04             	lea    0x4(%eax),%edx
80106437:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643a:	89 02                	mov    %eax,(%edx)
  return 0;
8010643c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106441:	c9                   	leave  
80106442:	c3                   	ret    

80106443 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106443:	55                   	push   %ebp
80106444:	89 e5                	mov    %esp,%ebp
80106446:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106449:	e8 5c e3 ff ff       	call   801047aa <fork>
}
8010644e:	c9                   	leave  
8010644f:	c3                   	ret    

80106450 <sys_exit>:

int
sys_exit(void)
{
80106450:	55                   	push   %ebp
80106451:	89 e5                	mov    %esp,%ebp
80106453:	83 ec 08             	sub    $0x8,%esp
  exit();
80106456:	e8 ca e4 ff ff       	call   80104925 <exit>
  return 0;  // not reached
8010645b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106460:	c9                   	leave  
80106461:	c3                   	ret    

80106462 <sys_wait>:

int
sys_wait(void)
{
80106462:	55                   	push   %ebp
80106463:	89 e5                	mov    %esp,%ebp
80106465:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106468:	e8 da e5 ff ff       	call   80104a47 <wait>
}
8010646d:	c9                   	leave  
8010646e:	c3                   	ret    

8010646f <sys_kill>:

int
sys_kill(void)
{
8010646f:	55                   	push   %ebp
80106470:	89 e5                	mov    %esp,%ebp
80106472:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106475:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106478:	89 44 24 04          	mov    %eax,0x4(%esp)
8010647c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106483:	e8 e9 f0 ff ff       	call   80105571 <argint>
80106488:	85 c0                	test   %eax,%eax
8010648a:	79 07                	jns    80106493 <sys_kill+0x24>
    return -1;
8010648c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106491:	eb 0b                	jmp    8010649e <sys_kill+0x2f>
  return kill(pid);
80106493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106496:	89 04 24             	mov    %eax,(%esp)
80106499:	e8 77 e9 ff ff       	call   80104e15 <kill>
}
8010649e:	c9                   	leave  
8010649f:	c3                   	ret    

801064a0 <sys_getpid>:

int
sys_getpid(void)
{
801064a0:	55                   	push   %ebp
801064a1:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801064a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064a9:	8b 40 10             	mov    0x10(%eax),%eax
}
801064ac:	5d                   	pop    %ebp
801064ad:	c3                   	ret    

801064ae <sys_sbrk>:

int
sys_sbrk(void)
{
801064ae:	55                   	push   %ebp
801064af:	89 e5                	mov    %esp,%ebp
801064b1:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801064b4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801064bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064c2:	e8 aa f0 ff ff       	call   80105571 <argint>
801064c7:	85 c0                	test   %eax,%eax
801064c9:	79 07                	jns    801064d2 <sys_sbrk+0x24>
    return -1;
801064cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064d0:	eb 24                	jmp    801064f6 <sys_sbrk+0x48>
  addr = proc->sz;
801064d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d8:	8b 00                	mov    (%eax),%eax
801064da:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801064dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e0:	89 04 24             	mov    %eax,(%esp)
801064e3:	e8 1d e2 ff ff       	call   80104705 <growproc>
801064e8:	85 c0                	test   %eax,%eax
801064ea:	79 07                	jns    801064f3 <sys_sbrk+0x45>
    return -1;
801064ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064f1:	eb 03                	jmp    801064f6 <sys_sbrk+0x48>
  return addr;
801064f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801064f6:	c9                   	leave  
801064f7:	c3                   	ret    

801064f8 <sys_sleep>:

int
sys_sleep(void)
{
801064f8:	55                   	push   %ebp
801064f9:	89 e5                	mov    %esp,%ebp
801064fb:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801064fe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106501:	89 44 24 04          	mov    %eax,0x4(%esp)
80106505:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010650c:	e8 60 f0 ff ff       	call   80105571 <argint>
80106511:	85 c0                	test   %eax,%eax
80106513:	79 07                	jns    8010651c <sys_sleep+0x24>
    return -1;
80106515:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010651a:	eb 6c                	jmp    80106588 <sys_sleep+0x90>
  acquire(&tickslock);
8010651c:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106523:	e8 b3 ea ff ff       	call   80104fdb <acquire>
  ticks0 = ticks;
80106528:	a1 e0 50 11 80       	mov    0x801150e0,%eax
8010652d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106530:	eb 34                	jmp    80106566 <sys_sleep+0x6e>
    if(proc->killed){
80106532:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106538:	8b 40 24             	mov    0x24(%eax),%eax
8010653b:	85 c0                	test   %eax,%eax
8010653d:	74 13                	je     80106552 <sys_sleep+0x5a>
      release(&tickslock);
8010653f:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106546:	e8 f2 ea ff ff       	call   8010503d <release>
      return -1;
8010654b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106550:	eb 36                	jmp    80106588 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106552:	c7 44 24 04 a0 48 11 	movl   $0x801148a0,0x4(%esp)
80106559:	80 
8010655a:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
80106561:	e8 ab e7 ff ff       	call   80104d11 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106566:	a1 e0 50 11 80       	mov    0x801150e0,%eax
8010656b:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010656e:	89 c2                	mov    %eax,%edx
80106570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106573:	39 c2                	cmp    %eax,%edx
80106575:	72 bb                	jb     80106532 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106577:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010657e:	e8 ba ea ff ff       	call   8010503d <release>
  return 0;
80106583:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106588:	c9                   	leave  
80106589:	c3                   	ret    

8010658a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010658a:	55                   	push   %ebp
8010658b:	89 e5                	mov    %esp,%ebp
8010658d:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106590:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106597:	e8 3f ea ff ff       	call   80104fdb <acquire>
  xticks = ticks;
8010659c:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801065a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801065a4:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801065ab:	e8 8d ea ff ff       	call   8010503d <release>
  return xticks;
801065b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801065b3:	c9                   	leave  
801065b4:	c3                   	ret    

801065b5 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801065b5:	55                   	push   %ebp
801065b6:	89 e5                	mov    %esp,%ebp
801065b8:	83 ec 08             	sub    $0x8,%esp
801065bb:	8b 55 08             	mov    0x8(%ebp),%edx
801065be:	8b 45 0c             	mov    0xc(%ebp),%eax
801065c1:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801065c5:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801065c8:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801065cc:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801065d0:	ee                   	out    %al,(%dx)
}
801065d1:	c9                   	leave  
801065d2:	c3                   	ret    

801065d3 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801065d3:	55                   	push   %ebp
801065d4:	89 e5                	mov    %esp,%ebp
801065d6:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801065d9:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801065e0:	00 
801065e1:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801065e8:	e8 c8 ff ff ff       	call   801065b5 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801065ed:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801065f4:	00 
801065f5:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801065fc:	e8 b4 ff ff ff       	call   801065b5 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106601:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106608:	00 
80106609:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106610:	e8 a0 ff ff ff       	call   801065b5 <outb>
  picenable(IRQ_TIMER);
80106615:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010661c:	e8 71 d9 ff ff       	call   80103f92 <picenable>
}
80106621:	c9                   	leave  
80106622:	c3                   	ret    

80106623 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106623:	1e                   	push   %ds
  pushl %es
80106624:	06                   	push   %es
  pushl %fs
80106625:	0f a0                	push   %fs
  pushl %gs
80106627:	0f a8                	push   %gs
  pushal
80106629:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010662a:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010662e:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106630:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106632:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106636:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106638:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010663a:	54                   	push   %esp
  call trap
8010663b:	e8 d8 01 00 00       	call   80106818 <trap>
  addl $4, %esp
80106640:	83 c4 04             	add    $0x4,%esp

80106643 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106643:	61                   	popa   
  popl %gs
80106644:	0f a9                	pop    %gs
  popl %fs
80106646:	0f a1                	pop    %fs
  popl %es
80106648:	07                   	pop    %es
  popl %ds
80106649:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010664a:	83 c4 08             	add    $0x8,%esp
  iret
8010664d:	cf                   	iret   

8010664e <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010664e:	55                   	push   %ebp
8010664f:	89 e5                	mov    %esp,%ebp
80106651:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106654:	8b 45 0c             	mov    0xc(%ebp),%eax
80106657:	83 e8 01             	sub    $0x1,%eax
8010665a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010665e:	8b 45 08             	mov    0x8(%ebp),%eax
80106661:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106665:	8b 45 08             	mov    0x8(%ebp),%eax
80106668:	c1 e8 10             	shr    $0x10,%eax
8010666b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010666f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106672:	0f 01 18             	lidtl  (%eax)
}
80106675:	c9                   	leave  
80106676:	c3                   	ret    

80106677 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106677:	55                   	push   %ebp
80106678:	89 e5                	mov    %esp,%ebp
8010667a:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010667d:	0f 20 d0             	mov    %cr2,%eax
80106680:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106683:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106686:	c9                   	leave  
80106687:	c3                   	ret    

80106688 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106688:	55                   	push   %ebp
80106689:	89 e5                	mov    %esp,%ebp
8010668b:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
8010668e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106695:	e9 c3 00 00 00       	jmp    8010675d <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010669a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010669d:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801066a4:	89 c2                	mov    %eax,%edx
801066a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a9:	66 89 14 c5 e0 48 11 	mov    %dx,-0x7feeb720(,%eax,8)
801066b0:	80 
801066b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066b4:	66 c7 04 c5 e2 48 11 	movw   $0x8,-0x7feeb71e(,%eax,8)
801066bb:	80 08 00 
801066be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c1:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
801066c8:	80 
801066c9:	83 e2 e0             	and    $0xffffffe0,%edx
801066cc:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
801066d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d6:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
801066dd:	80 
801066de:	83 e2 1f             	and    $0x1f,%edx
801066e1:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
801066e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066eb:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801066f2:	80 
801066f3:	83 e2 f0             	and    $0xfffffff0,%edx
801066f6:	83 ca 0e             	or     $0xe,%edx
801066f9:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
80106700:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106703:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
8010670a:	80 
8010670b:	83 e2 ef             	and    $0xffffffef,%edx
8010670e:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
80106715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106718:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
8010671f:	80 
80106720:	83 e2 9f             	and    $0xffffff9f,%edx
80106723:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
8010672a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010672d:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
80106734:	80 
80106735:	83 ca 80             	or     $0xffffff80,%edx
80106738:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
8010673f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106742:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106749:	c1 e8 10             	shr    $0x10,%eax
8010674c:	89 c2                	mov    %eax,%edx
8010674e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106751:	66 89 14 c5 e6 48 11 	mov    %dx,-0x7feeb71a(,%eax,8)
80106758:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106759:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010675d:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106764:	0f 8e 30 ff ff ff    	jle    8010669a <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010676a:	a1 98 b1 10 80       	mov    0x8010b198,%eax
8010676f:	66 a3 e0 4a 11 80    	mov    %ax,0x80114ae0
80106775:	66 c7 05 e2 4a 11 80 	movw   $0x8,0x80114ae2
8010677c:	08 00 
8010677e:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
80106785:	83 e0 e0             	and    $0xffffffe0,%eax
80106788:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
8010678d:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
80106794:	83 e0 1f             	and    $0x1f,%eax
80106797:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
8010679c:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801067a3:	83 c8 0f             	or     $0xf,%eax
801067a6:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801067ab:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801067b2:	83 e0 ef             	and    $0xffffffef,%eax
801067b5:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801067ba:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801067c1:	83 c8 60             	or     $0x60,%eax
801067c4:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801067c9:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801067d0:	83 c8 80             	or     $0xffffff80,%eax
801067d3:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801067d8:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801067dd:	c1 e8 10             	shr    $0x10,%eax
801067e0:	66 a3 e6 4a 11 80    	mov    %ax,0x80114ae6
  
  initlock(&tickslock, "time");
801067e6:	c7 44 24 04 74 8a 10 	movl   $0x80108a74,0x4(%esp)
801067ed:	80 
801067ee:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801067f5:	e8 c0 e7 ff ff       	call   80104fba <initlock>
}
801067fa:	c9                   	leave  
801067fb:	c3                   	ret    

801067fc <idtinit>:

void
idtinit(void)
{
801067fc:	55                   	push   %ebp
801067fd:	89 e5                	mov    %esp,%ebp
801067ff:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106802:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106809:	00 
8010680a:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106811:	e8 38 fe ff ff       	call   8010664e <lidt>
}
80106816:	c9                   	leave  
80106817:	c3                   	ret    

80106818 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106818:	55                   	push   %ebp
80106819:	89 e5                	mov    %esp,%ebp
8010681b:	57                   	push   %edi
8010681c:	56                   	push   %esi
8010681d:	53                   	push   %ebx
8010681e:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106821:	8b 45 08             	mov    0x8(%ebp),%eax
80106824:	8b 40 30             	mov    0x30(%eax),%eax
80106827:	83 f8 40             	cmp    $0x40,%eax
8010682a:	75 3f                	jne    8010686b <trap+0x53>
    if(proc->killed)
8010682c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106832:	8b 40 24             	mov    0x24(%eax),%eax
80106835:	85 c0                	test   %eax,%eax
80106837:	74 05                	je     8010683e <trap+0x26>
      exit();
80106839:	e8 e7 e0 ff ff       	call   80104925 <exit>
    proc->tf = tf;
8010683e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106844:	8b 55 08             	mov    0x8(%ebp),%edx
80106847:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010684a:	e8 e9 ed ff ff       	call   80105638 <syscall>
    if(proc->killed)
8010684f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106855:	8b 40 24             	mov    0x24(%eax),%eax
80106858:	85 c0                	test   %eax,%eax
8010685a:	74 0a                	je     80106866 <trap+0x4e>
      exit();
8010685c:	e8 c4 e0 ff ff       	call   80104925 <exit>
    return;
80106861:	e9 2d 02 00 00       	jmp    80106a93 <trap+0x27b>
80106866:	e9 28 02 00 00       	jmp    80106a93 <trap+0x27b>
  }

  switch(tf->trapno){
8010686b:	8b 45 08             	mov    0x8(%ebp),%eax
8010686e:	8b 40 30             	mov    0x30(%eax),%eax
80106871:	83 e8 20             	sub    $0x20,%eax
80106874:	83 f8 1f             	cmp    $0x1f,%eax
80106877:	0f 87 bc 00 00 00    	ja     80106939 <trap+0x121>
8010687d:	8b 04 85 1c 8b 10 80 	mov    -0x7fef74e4(,%eax,4),%eax
80106884:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106886:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010688c:	0f b6 00             	movzbl (%eax),%eax
8010688f:	84 c0                	test   %al,%al
80106891:	75 31                	jne    801068c4 <trap+0xac>
      acquire(&tickslock);
80106893:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010689a:	e8 3c e7 ff ff       	call   80104fdb <acquire>
      ticks++;
8010689f:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801068a4:	83 c0 01             	add    $0x1,%eax
801068a7:	a3 e0 50 11 80       	mov    %eax,0x801150e0
      wakeup(&ticks);
801068ac:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
801068b3:	e8 32 e5 ff ff       	call   80104dea <wakeup>
      release(&tickslock);
801068b8:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801068bf:	e8 79 e7 ff ff       	call   8010503d <release>
    }
    lapiceoi();
801068c4:	e8 f4 c7 ff ff       	call   801030bd <lapiceoi>
    break;
801068c9:	e9 41 01 00 00       	jmp    80106a0f <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801068ce:	e8 f8 bf ff ff       	call   801028cb <ideintr>
    lapiceoi();
801068d3:	e8 e5 c7 ff ff       	call   801030bd <lapiceoi>
    break;
801068d8:	e9 32 01 00 00       	jmp    80106a0f <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801068dd:	e8 aa c5 ff ff       	call   80102e8c <kbdintr>
    lapiceoi();
801068e2:	e8 d6 c7 ff ff       	call   801030bd <lapiceoi>
    break;
801068e7:	e9 23 01 00 00       	jmp    80106a0f <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801068ec:	e8 97 03 00 00       	call   80106c88 <uartintr>
    lapiceoi();
801068f1:	e8 c7 c7 ff ff       	call   801030bd <lapiceoi>
    break;
801068f6:	e9 14 01 00 00       	jmp    80106a0f <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801068fb:	8b 45 08             	mov    0x8(%ebp),%eax
801068fe:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106901:	8b 45 08             	mov    0x8(%ebp),%eax
80106904:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106908:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010690b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106911:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106914:	0f b6 c0             	movzbl %al,%eax
80106917:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010691b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010691f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106923:	c7 04 24 7c 8a 10 80 	movl   $0x80108a7c,(%esp)
8010692a:	e8 71 9a ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010692f:	e8 89 c7 ff ff       	call   801030bd <lapiceoi>
    break;
80106934:	e9 d6 00 00 00       	jmp    80106a0f <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106939:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010693f:	85 c0                	test   %eax,%eax
80106941:	74 11                	je     80106954 <trap+0x13c>
80106943:	8b 45 08             	mov    0x8(%ebp),%eax
80106946:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010694a:	0f b7 c0             	movzwl %ax,%eax
8010694d:	83 e0 03             	and    $0x3,%eax
80106950:	85 c0                	test   %eax,%eax
80106952:	75 46                	jne    8010699a <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106954:	e8 1e fd ff ff       	call   80106677 <rcr2>
80106959:	8b 55 08             	mov    0x8(%ebp),%edx
8010695c:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010695f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106966:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106969:	0f b6 ca             	movzbl %dl,%ecx
8010696c:	8b 55 08             	mov    0x8(%ebp),%edx
8010696f:	8b 52 30             	mov    0x30(%edx),%edx
80106972:	89 44 24 10          	mov    %eax,0x10(%esp)
80106976:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010697a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010697e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106982:	c7 04 24 a0 8a 10 80 	movl   $0x80108aa0,(%esp)
80106989:	e8 12 9a ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010698e:	c7 04 24 d2 8a 10 80 	movl   $0x80108ad2,(%esp)
80106995:	e8 a0 9b ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010699a:	e8 d8 fc ff ff       	call   80106677 <rcr2>
8010699f:	89 c2                	mov    %eax,%edx
801069a1:	8b 45 08             	mov    0x8(%ebp),%eax
801069a4:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069a7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801069ad:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069b0:	0f b6 f0             	movzbl %al,%esi
801069b3:	8b 45 08             	mov    0x8(%ebp),%eax
801069b6:	8b 58 34             	mov    0x34(%eax),%ebx
801069b9:	8b 45 08             	mov    0x8(%ebp),%eax
801069bc:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069c5:	83 c0 6c             	add    $0x6c,%eax
801069c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801069cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069d1:	8b 40 10             	mov    0x10(%eax),%eax
801069d4:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801069d8:	89 7c 24 18          	mov    %edi,0x18(%esp)
801069dc:	89 74 24 14          	mov    %esi,0x14(%esp)
801069e0:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801069e4:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801069e8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801069eb:	89 74 24 08          	mov    %esi,0x8(%esp)
801069ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801069f3:	c7 04 24 d8 8a 10 80 	movl   $0x80108ad8,(%esp)
801069fa:	e8 a1 99 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801069ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a05:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106a0c:	eb 01                	jmp    80106a0f <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106a0e:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a0f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a15:	85 c0                	test   %eax,%eax
80106a17:	74 24                	je     80106a3d <trap+0x225>
80106a19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a1f:	8b 40 24             	mov    0x24(%eax),%eax
80106a22:	85 c0                	test   %eax,%eax
80106a24:	74 17                	je     80106a3d <trap+0x225>
80106a26:	8b 45 08             	mov    0x8(%ebp),%eax
80106a29:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a2d:	0f b7 c0             	movzwl %ax,%eax
80106a30:	83 e0 03             	and    $0x3,%eax
80106a33:	83 f8 03             	cmp    $0x3,%eax
80106a36:	75 05                	jne    80106a3d <trap+0x225>
    exit();
80106a38:	e8 e8 de ff ff       	call   80104925 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106a3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a43:	85 c0                	test   %eax,%eax
80106a45:	74 1e                	je     80106a65 <trap+0x24d>
80106a47:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a4d:	8b 40 0c             	mov    0xc(%eax),%eax
80106a50:	83 f8 04             	cmp    $0x4,%eax
80106a53:	75 10                	jne    80106a65 <trap+0x24d>
80106a55:	8b 45 08             	mov    0x8(%ebp),%eax
80106a58:	8b 40 30             	mov    0x30(%eax),%eax
80106a5b:	83 f8 20             	cmp    $0x20,%eax
80106a5e:	75 05                	jne    80106a65 <trap+0x24d>
    yield();
80106a60:	e8 3b e2 ff ff       	call   80104ca0 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a6b:	85 c0                	test   %eax,%eax
80106a6d:	74 24                	je     80106a93 <trap+0x27b>
80106a6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a75:	8b 40 24             	mov    0x24(%eax),%eax
80106a78:	85 c0                	test   %eax,%eax
80106a7a:	74 17                	je     80106a93 <trap+0x27b>
80106a7c:	8b 45 08             	mov    0x8(%ebp),%eax
80106a7f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a83:	0f b7 c0             	movzwl %ax,%eax
80106a86:	83 e0 03             	and    $0x3,%eax
80106a89:	83 f8 03             	cmp    $0x3,%eax
80106a8c:	75 05                	jne    80106a93 <trap+0x27b>
    exit();
80106a8e:	e8 92 de ff ff       	call   80104925 <exit>
}
80106a93:	83 c4 3c             	add    $0x3c,%esp
80106a96:	5b                   	pop    %ebx
80106a97:	5e                   	pop    %esi
80106a98:	5f                   	pop    %edi
80106a99:	5d                   	pop    %ebp
80106a9a:	c3                   	ret    

80106a9b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106a9b:	55                   	push   %ebp
80106a9c:	89 e5                	mov    %esp,%ebp
80106a9e:	83 ec 14             	sub    $0x14,%esp
80106aa1:	8b 45 08             	mov    0x8(%ebp),%eax
80106aa4:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106aa8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106aac:	89 c2                	mov    %eax,%edx
80106aae:	ec                   	in     (%dx),%al
80106aaf:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106ab2:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106ab6:	c9                   	leave  
80106ab7:	c3                   	ret    

80106ab8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106ab8:	55                   	push   %ebp
80106ab9:	89 e5                	mov    %esp,%ebp
80106abb:	83 ec 08             	sub    $0x8,%esp
80106abe:	8b 55 08             	mov    0x8(%ebp),%edx
80106ac1:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ac4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106ac8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106acb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106acf:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106ad3:	ee                   	out    %al,(%dx)
}
80106ad4:	c9                   	leave  
80106ad5:	c3                   	ret    

80106ad6 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106ad6:	55                   	push   %ebp
80106ad7:	89 e5                	mov    %esp,%ebp
80106ad9:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106adc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ae3:	00 
80106ae4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106aeb:	e8 c8 ff ff ff       	call   80106ab8 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106af0:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106af7:	00 
80106af8:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106aff:	e8 b4 ff ff ff       	call   80106ab8 <outb>
  outb(COM1+0, 115200/9600);
80106b04:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106b0b:	00 
80106b0c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b13:	e8 a0 ff ff ff       	call   80106ab8 <outb>
  outb(COM1+1, 0);
80106b18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b1f:	00 
80106b20:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b27:	e8 8c ff ff ff       	call   80106ab8 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106b2c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106b33:	00 
80106b34:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b3b:	e8 78 ff ff ff       	call   80106ab8 <outb>
  outb(COM1+4, 0);
80106b40:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b47:	00 
80106b48:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106b4f:	e8 64 ff ff ff       	call   80106ab8 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106b54:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b5b:	00 
80106b5c:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b63:	e8 50 ff ff ff       	call   80106ab8 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106b68:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b6f:	e8 27 ff ff ff       	call   80106a9b <inb>
80106b74:	3c ff                	cmp    $0xff,%al
80106b76:	75 02                	jne    80106b7a <uartinit+0xa4>
    return;
80106b78:	eb 6a                	jmp    80106be4 <uartinit+0x10e>
  uart = 1;
80106b7a:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106b81:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106b84:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106b8b:	e8 0b ff ff ff       	call   80106a9b <inb>
  inb(COM1+0);
80106b90:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b97:	e8 ff fe ff ff       	call   80106a9b <inb>
  picenable(IRQ_COM1);
80106b9c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106ba3:	e8 ea d3 ff ff       	call   80103f92 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106ba8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106baf:	00 
80106bb0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106bb7:	e8 8e bf ff ff       	call   80102b4a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106bbc:	c7 45 f4 9c 8b 10 80 	movl   $0x80108b9c,-0xc(%ebp)
80106bc3:	eb 15                	jmp    80106bda <uartinit+0x104>
    uartputc(*p);
80106bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bc8:	0f b6 00             	movzbl (%eax),%eax
80106bcb:	0f be c0             	movsbl %al,%eax
80106bce:	89 04 24             	mov    %eax,(%esp)
80106bd1:	e8 10 00 00 00       	call   80106be6 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106bd6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bdd:	0f b6 00             	movzbl (%eax),%eax
80106be0:	84 c0                	test   %al,%al
80106be2:	75 e1                	jne    80106bc5 <uartinit+0xef>
    uartputc(*p);
}
80106be4:	c9                   	leave  
80106be5:	c3                   	ret    

80106be6 <uartputc>:

void
uartputc(int c)
{
80106be6:	55                   	push   %ebp
80106be7:	89 e5                	mov    %esp,%ebp
80106be9:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106bec:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106bf1:	85 c0                	test   %eax,%eax
80106bf3:	75 02                	jne    80106bf7 <uartputc+0x11>
    return;
80106bf5:	eb 4b                	jmp    80106c42 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106bf7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106bfe:	eb 10                	jmp    80106c10 <uartputc+0x2a>
    microdelay(10);
80106c00:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106c07:	e8 d6 c4 ff ff       	call   801030e2 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c0c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c10:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106c14:	7f 16                	jg     80106c2c <uartputc+0x46>
80106c16:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c1d:	e8 79 fe ff ff       	call   80106a9b <inb>
80106c22:	0f b6 c0             	movzbl %al,%eax
80106c25:	83 e0 20             	and    $0x20,%eax
80106c28:	85 c0                	test   %eax,%eax
80106c2a:	74 d4                	je     80106c00 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106c2c:	8b 45 08             	mov    0x8(%ebp),%eax
80106c2f:	0f b6 c0             	movzbl %al,%eax
80106c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c36:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c3d:	e8 76 fe ff ff       	call   80106ab8 <outb>
}
80106c42:	c9                   	leave  
80106c43:	c3                   	ret    

80106c44 <uartgetc>:

static int
uartgetc(void)
{
80106c44:	55                   	push   %ebp
80106c45:	89 e5                	mov    %esp,%ebp
80106c47:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106c4a:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106c4f:	85 c0                	test   %eax,%eax
80106c51:	75 07                	jne    80106c5a <uartgetc+0x16>
    return -1;
80106c53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c58:	eb 2c                	jmp    80106c86 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106c5a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c61:	e8 35 fe ff ff       	call   80106a9b <inb>
80106c66:	0f b6 c0             	movzbl %al,%eax
80106c69:	83 e0 01             	and    $0x1,%eax
80106c6c:	85 c0                	test   %eax,%eax
80106c6e:	75 07                	jne    80106c77 <uartgetc+0x33>
    return -1;
80106c70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c75:	eb 0f                	jmp    80106c86 <uartgetc+0x42>
  return inb(COM1+0);
80106c77:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c7e:	e8 18 fe ff ff       	call   80106a9b <inb>
80106c83:	0f b6 c0             	movzbl %al,%eax
}
80106c86:	c9                   	leave  
80106c87:	c3                   	ret    

80106c88 <uartintr>:

void
uartintr(void)
{
80106c88:	55                   	push   %ebp
80106c89:	89 e5                	mov    %esp,%ebp
80106c8b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106c8e:	c7 04 24 44 6c 10 80 	movl   $0x80106c44,(%esp)
80106c95:	e8 2e 9b ff ff       	call   801007c8 <consoleintr>
}
80106c9a:	c9                   	leave  
80106c9b:	c3                   	ret    

80106c9c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106c9c:	6a 00                	push   $0x0
  pushl $0
80106c9e:	6a 00                	push   $0x0
  jmp alltraps
80106ca0:	e9 7e f9 ff ff       	jmp    80106623 <alltraps>

80106ca5 <vector1>:
.globl vector1
vector1:
  pushl $0
80106ca5:	6a 00                	push   $0x0
  pushl $1
80106ca7:	6a 01                	push   $0x1
  jmp alltraps
80106ca9:	e9 75 f9 ff ff       	jmp    80106623 <alltraps>

80106cae <vector2>:
.globl vector2
vector2:
  pushl $0
80106cae:	6a 00                	push   $0x0
  pushl $2
80106cb0:	6a 02                	push   $0x2
  jmp alltraps
80106cb2:	e9 6c f9 ff ff       	jmp    80106623 <alltraps>

80106cb7 <vector3>:
.globl vector3
vector3:
  pushl $0
80106cb7:	6a 00                	push   $0x0
  pushl $3
80106cb9:	6a 03                	push   $0x3
  jmp alltraps
80106cbb:	e9 63 f9 ff ff       	jmp    80106623 <alltraps>

80106cc0 <vector4>:
.globl vector4
vector4:
  pushl $0
80106cc0:	6a 00                	push   $0x0
  pushl $4
80106cc2:	6a 04                	push   $0x4
  jmp alltraps
80106cc4:	e9 5a f9 ff ff       	jmp    80106623 <alltraps>

80106cc9 <vector5>:
.globl vector5
vector5:
  pushl $0
80106cc9:	6a 00                	push   $0x0
  pushl $5
80106ccb:	6a 05                	push   $0x5
  jmp alltraps
80106ccd:	e9 51 f9 ff ff       	jmp    80106623 <alltraps>

80106cd2 <vector6>:
.globl vector6
vector6:
  pushl $0
80106cd2:	6a 00                	push   $0x0
  pushl $6
80106cd4:	6a 06                	push   $0x6
  jmp alltraps
80106cd6:	e9 48 f9 ff ff       	jmp    80106623 <alltraps>

80106cdb <vector7>:
.globl vector7
vector7:
  pushl $0
80106cdb:	6a 00                	push   $0x0
  pushl $7
80106cdd:	6a 07                	push   $0x7
  jmp alltraps
80106cdf:	e9 3f f9 ff ff       	jmp    80106623 <alltraps>

80106ce4 <vector8>:
.globl vector8
vector8:
  pushl $8
80106ce4:	6a 08                	push   $0x8
  jmp alltraps
80106ce6:	e9 38 f9 ff ff       	jmp    80106623 <alltraps>

80106ceb <vector9>:
.globl vector9
vector9:
  pushl $0
80106ceb:	6a 00                	push   $0x0
  pushl $9
80106ced:	6a 09                	push   $0x9
  jmp alltraps
80106cef:	e9 2f f9 ff ff       	jmp    80106623 <alltraps>

80106cf4 <vector10>:
.globl vector10
vector10:
  pushl $10
80106cf4:	6a 0a                	push   $0xa
  jmp alltraps
80106cf6:	e9 28 f9 ff ff       	jmp    80106623 <alltraps>

80106cfb <vector11>:
.globl vector11
vector11:
  pushl $11
80106cfb:	6a 0b                	push   $0xb
  jmp alltraps
80106cfd:	e9 21 f9 ff ff       	jmp    80106623 <alltraps>

80106d02 <vector12>:
.globl vector12
vector12:
  pushl $12
80106d02:	6a 0c                	push   $0xc
  jmp alltraps
80106d04:	e9 1a f9 ff ff       	jmp    80106623 <alltraps>

80106d09 <vector13>:
.globl vector13
vector13:
  pushl $13
80106d09:	6a 0d                	push   $0xd
  jmp alltraps
80106d0b:	e9 13 f9 ff ff       	jmp    80106623 <alltraps>

80106d10 <vector14>:
.globl vector14
vector14:
  pushl $14
80106d10:	6a 0e                	push   $0xe
  jmp alltraps
80106d12:	e9 0c f9 ff ff       	jmp    80106623 <alltraps>

80106d17 <vector15>:
.globl vector15
vector15:
  pushl $0
80106d17:	6a 00                	push   $0x0
  pushl $15
80106d19:	6a 0f                	push   $0xf
  jmp alltraps
80106d1b:	e9 03 f9 ff ff       	jmp    80106623 <alltraps>

80106d20 <vector16>:
.globl vector16
vector16:
  pushl $0
80106d20:	6a 00                	push   $0x0
  pushl $16
80106d22:	6a 10                	push   $0x10
  jmp alltraps
80106d24:	e9 fa f8 ff ff       	jmp    80106623 <alltraps>

80106d29 <vector17>:
.globl vector17
vector17:
  pushl $17
80106d29:	6a 11                	push   $0x11
  jmp alltraps
80106d2b:	e9 f3 f8 ff ff       	jmp    80106623 <alltraps>

80106d30 <vector18>:
.globl vector18
vector18:
  pushl $0
80106d30:	6a 00                	push   $0x0
  pushl $18
80106d32:	6a 12                	push   $0x12
  jmp alltraps
80106d34:	e9 ea f8 ff ff       	jmp    80106623 <alltraps>

80106d39 <vector19>:
.globl vector19
vector19:
  pushl $0
80106d39:	6a 00                	push   $0x0
  pushl $19
80106d3b:	6a 13                	push   $0x13
  jmp alltraps
80106d3d:	e9 e1 f8 ff ff       	jmp    80106623 <alltraps>

80106d42 <vector20>:
.globl vector20
vector20:
  pushl $0
80106d42:	6a 00                	push   $0x0
  pushl $20
80106d44:	6a 14                	push   $0x14
  jmp alltraps
80106d46:	e9 d8 f8 ff ff       	jmp    80106623 <alltraps>

80106d4b <vector21>:
.globl vector21
vector21:
  pushl $0
80106d4b:	6a 00                	push   $0x0
  pushl $21
80106d4d:	6a 15                	push   $0x15
  jmp alltraps
80106d4f:	e9 cf f8 ff ff       	jmp    80106623 <alltraps>

80106d54 <vector22>:
.globl vector22
vector22:
  pushl $0
80106d54:	6a 00                	push   $0x0
  pushl $22
80106d56:	6a 16                	push   $0x16
  jmp alltraps
80106d58:	e9 c6 f8 ff ff       	jmp    80106623 <alltraps>

80106d5d <vector23>:
.globl vector23
vector23:
  pushl $0
80106d5d:	6a 00                	push   $0x0
  pushl $23
80106d5f:	6a 17                	push   $0x17
  jmp alltraps
80106d61:	e9 bd f8 ff ff       	jmp    80106623 <alltraps>

80106d66 <vector24>:
.globl vector24
vector24:
  pushl $0
80106d66:	6a 00                	push   $0x0
  pushl $24
80106d68:	6a 18                	push   $0x18
  jmp alltraps
80106d6a:	e9 b4 f8 ff ff       	jmp    80106623 <alltraps>

80106d6f <vector25>:
.globl vector25
vector25:
  pushl $0
80106d6f:	6a 00                	push   $0x0
  pushl $25
80106d71:	6a 19                	push   $0x19
  jmp alltraps
80106d73:	e9 ab f8 ff ff       	jmp    80106623 <alltraps>

80106d78 <vector26>:
.globl vector26
vector26:
  pushl $0
80106d78:	6a 00                	push   $0x0
  pushl $26
80106d7a:	6a 1a                	push   $0x1a
  jmp alltraps
80106d7c:	e9 a2 f8 ff ff       	jmp    80106623 <alltraps>

80106d81 <vector27>:
.globl vector27
vector27:
  pushl $0
80106d81:	6a 00                	push   $0x0
  pushl $27
80106d83:	6a 1b                	push   $0x1b
  jmp alltraps
80106d85:	e9 99 f8 ff ff       	jmp    80106623 <alltraps>

80106d8a <vector28>:
.globl vector28
vector28:
  pushl $0
80106d8a:	6a 00                	push   $0x0
  pushl $28
80106d8c:	6a 1c                	push   $0x1c
  jmp alltraps
80106d8e:	e9 90 f8 ff ff       	jmp    80106623 <alltraps>

80106d93 <vector29>:
.globl vector29
vector29:
  pushl $0
80106d93:	6a 00                	push   $0x0
  pushl $29
80106d95:	6a 1d                	push   $0x1d
  jmp alltraps
80106d97:	e9 87 f8 ff ff       	jmp    80106623 <alltraps>

80106d9c <vector30>:
.globl vector30
vector30:
  pushl $0
80106d9c:	6a 00                	push   $0x0
  pushl $30
80106d9e:	6a 1e                	push   $0x1e
  jmp alltraps
80106da0:	e9 7e f8 ff ff       	jmp    80106623 <alltraps>

80106da5 <vector31>:
.globl vector31
vector31:
  pushl $0
80106da5:	6a 00                	push   $0x0
  pushl $31
80106da7:	6a 1f                	push   $0x1f
  jmp alltraps
80106da9:	e9 75 f8 ff ff       	jmp    80106623 <alltraps>

80106dae <vector32>:
.globl vector32
vector32:
  pushl $0
80106dae:	6a 00                	push   $0x0
  pushl $32
80106db0:	6a 20                	push   $0x20
  jmp alltraps
80106db2:	e9 6c f8 ff ff       	jmp    80106623 <alltraps>

80106db7 <vector33>:
.globl vector33
vector33:
  pushl $0
80106db7:	6a 00                	push   $0x0
  pushl $33
80106db9:	6a 21                	push   $0x21
  jmp alltraps
80106dbb:	e9 63 f8 ff ff       	jmp    80106623 <alltraps>

80106dc0 <vector34>:
.globl vector34
vector34:
  pushl $0
80106dc0:	6a 00                	push   $0x0
  pushl $34
80106dc2:	6a 22                	push   $0x22
  jmp alltraps
80106dc4:	e9 5a f8 ff ff       	jmp    80106623 <alltraps>

80106dc9 <vector35>:
.globl vector35
vector35:
  pushl $0
80106dc9:	6a 00                	push   $0x0
  pushl $35
80106dcb:	6a 23                	push   $0x23
  jmp alltraps
80106dcd:	e9 51 f8 ff ff       	jmp    80106623 <alltraps>

80106dd2 <vector36>:
.globl vector36
vector36:
  pushl $0
80106dd2:	6a 00                	push   $0x0
  pushl $36
80106dd4:	6a 24                	push   $0x24
  jmp alltraps
80106dd6:	e9 48 f8 ff ff       	jmp    80106623 <alltraps>

80106ddb <vector37>:
.globl vector37
vector37:
  pushl $0
80106ddb:	6a 00                	push   $0x0
  pushl $37
80106ddd:	6a 25                	push   $0x25
  jmp alltraps
80106ddf:	e9 3f f8 ff ff       	jmp    80106623 <alltraps>

80106de4 <vector38>:
.globl vector38
vector38:
  pushl $0
80106de4:	6a 00                	push   $0x0
  pushl $38
80106de6:	6a 26                	push   $0x26
  jmp alltraps
80106de8:	e9 36 f8 ff ff       	jmp    80106623 <alltraps>

80106ded <vector39>:
.globl vector39
vector39:
  pushl $0
80106ded:	6a 00                	push   $0x0
  pushl $39
80106def:	6a 27                	push   $0x27
  jmp alltraps
80106df1:	e9 2d f8 ff ff       	jmp    80106623 <alltraps>

80106df6 <vector40>:
.globl vector40
vector40:
  pushl $0
80106df6:	6a 00                	push   $0x0
  pushl $40
80106df8:	6a 28                	push   $0x28
  jmp alltraps
80106dfa:	e9 24 f8 ff ff       	jmp    80106623 <alltraps>

80106dff <vector41>:
.globl vector41
vector41:
  pushl $0
80106dff:	6a 00                	push   $0x0
  pushl $41
80106e01:	6a 29                	push   $0x29
  jmp alltraps
80106e03:	e9 1b f8 ff ff       	jmp    80106623 <alltraps>

80106e08 <vector42>:
.globl vector42
vector42:
  pushl $0
80106e08:	6a 00                	push   $0x0
  pushl $42
80106e0a:	6a 2a                	push   $0x2a
  jmp alltraps
80106e0c:	e9 12 f8 ff ff       	jmp    80106623 <alltraps>

80106e11 <vector43>:
.globl vector43
vector43:
  pushl $0
80106e11:	6a 00                	push   $0x0
  pushl $43
80106e13:	6a 2b                	push   $0x2b
  jmp alltraps
80106e15:	e9 09 f8 ff ff       	jmp    80106623 <alltraps>

80106e1a <vector44>:
.globl vector44
vector44:
  pushl $0
80106e1a:	6a 00                	push   $0x0
  pushl $44
80106e1c:	6a 2c                	push   $0x2c
  jmp alltraps
80106e1e:	e9 00 f8 ff ff       	jmp    80106623 <alltraps>

80106e23 <vector45>:
.globl vector45
vector45:
  pushl $0
80106e23:	6a 00                	push   $0x0
  pushl $45
80106e25:	6a 2d                	push   $0x2d
  jmp alltraps
80106e27:	e9 f7 f7 ff ff       	jmp    80106623 <alltraps>

80106e2c <vector46>:
.globl vector46
vector46:
  pushl $0
80106e2c:	6a 00                	push   $0x0
  pushl $46
80106e2e:	6a 2e                	push   $0x2e
  jmp alltraps
80106e30:	e9 ee f7 ff ff       	jmp    80106623 <alltraps>

80106e35 <vector47>:
.globl vector47
vector47:
  pushl $0
80106e35:	6a 00                	push   $0x0
  pushl $47
80106e37:	6a 2f                	push   $0x2f
  jmp alltraps
80106e39:	e9 e5 f7 ff ff       	jmp    80106623 <alltraps>

80106e3e <vector48>:
.globl vector48
vector48:
  pushl $0
80106e3e:	6a 00                	push   $0x0
  pushl $48
80106e40:	6a 30                	push   $0x30
  jmp alltraps
80106e42:	e9 dc f7 ff ff       	jmp    80106623 <alltraps>

80106e47 <vector49>:
.globl vector49
vector49:
  pushl $0
80106e47:	6a 00                	push   $0x0
  pushl $49
80106e49:	6a 31                	push   $0x31
  jmp alltraps
80106e4b:	e9 d3 f7 ff ff       	jmp    80106623 <alltraps>

80106e50 <vector50>:
.globl vector50
vector50:
  pushl $0
80106e50:	6a 00                	push   $0x0
  pushl $50
80106e52:	6a 32                	push   $0x32
  jmp alltraps
80106e54:	e9 ca f7 ff ff       	jmp    80106623 <alltraps>

80106e59 <vector51>:
.globl vector51
vector51:
  pushl $0
80106e59:	6a 00                	push   $0x0
  pushl $51
80106e5b:	6a 33                	push   $0x33
  jmp alltraps
80106e5d:	e9 c1 f7 ff ff       	jmp    80106623 <alltraps>

80106e62 <vector52>:
.globl vector52
vector52:
  pushl $0
80106e62:	6a 00                	push   $0x0
  pushl $52
80106e64:	6a 34                	push   $0x34
  jmp alltraps
80106e66:	e9 b8 f7 ff ff       	jmp    80106623 <alltraps>

80106e6b <vector53>:
.globl vector53
vector53:
  pushl $0
80106e6b:	6a 00                	push   $0x0
  pushl $53
80106e6d:	6a 35                	push   $0x35
  jmp alltraps
80106e6f:	e9 af f7 ff ff       	jmp    80106623 <alltraps>

80106e74 <vector54>:
.globl vector54
vector54:
  pushl $0
80106e74:	6a 00                	push   $0x0
  pushl $54
80106e76:	6a 36                	push   $0x36
  jmp alltraps
80106e78:	e9 a6 f7 ff ff       	jmp    80106623 <alltraps>

80106e7d <vector55>:
.globl vector55
vector55:
  pushl $0
80106e7d:	6a 00                	push   $0x0
  pushl $55
80106e7f:	6a 37                	push   $0x37
  jmp alltraps
80106e81:	e9 9d f7 ff ff       	jmp    80106623 <alltraps>

80106e86 <vector56>:
.globl vector56
vector56:
  pushl $0
80106e86:	6a 00                	push   $0x0
  pushl $56
80106e88:	6a 38                	push   $0x38
  jmp alltraps
80106e8a:	e9 94 f7 ff ff       	jmp    80106623 <alltraps>

80106e8f <vector57>:
.globl vector57
vector57:
  pushl $0
80106e8f:	6a 00                	push   $0x0
  pushl $57
80106e91:	6a 39                	push   $0x39
  jmp alltraps
80106e93:	e9 8b f7 ff ff       	jmp    80106623 <alltraps>

80106e98 <vector58>:
.globl vector58
vector58:
  pushl $0
80106e98:	6a 00                	push   $0x0
  pushl $58
80106e9a:	6a 3a                	push   $0x3a
  jmp alltraps
80106e9c:	e9 82 f7 ff ff       	jmp    80106623 <alltraps>

80106ea1 <vector59>:
.globl vector59
vector59:
  pushl $0
80106ea1:	6a 00                	push   $0x0
  pushl $59
80106ea3:	6a 3b                	push   $0x3b
  jmp alltraps
80106ea5:	e9 79 f7 ff ff       	jmp    80106623 <alltraps>

80106eaa <vector60>:
.globl vector60
vector60:
  pushl $0
80106eaa:	6a 00                	push   $0x0
  pushl $60
80106eac:	6a 3c                	push   $0x3c
  jmp alltraps
80106eae:	e9 70 f7 ff ff       	jmp    80106623 <alltraps>

80106eb3 <vector61>:
.globl vector61
vector61:
  pushl $0
80106eb3:	6a 00                	push   $0x0
  pushl $61
80106eb5:	6a 3d                	push   $0x3d
  jmp alltraps
80106eb7:	e9 67 f7 ff ff       	jmp    80106623 <alltraps>

80106ebc <vector62>:
.globl vector62
vector62:
  pushl $0
80106ebc:	6a 00                	push   $0x0
  pushl $62
80106ebe:	6a 3e                	push   $0x3e
  jmp alltraps
80106ec0:	e9 5e f7 ff ff       	jmp    80106623 <alltraps>

80106ec5 <vector63>:
.globl vector63
vector63:
  pushl $0
80106ec5:	6a 00                	push   $0x0
  pushl $63
80106ec7:	6a 3f                	push   $0x3f
  jmp alltraps
80106ec9:	e9 55 f7 ff ff       	jmp    80106623 <alltraps>

80106ece <vector64>:
.globl vector64
vector64:
  pushl $0
80106ece:	6a 00                	push   $0x0
  pushl $64
80106ed0:	6a 40                	push   $0x40
  jmp alltraps
80106ed2:	e9 4c f7 ff ff       	jmp    80106623 <alltraps>

80106ed7 <vector65>:
.globl vector65
vector65:
  pushl $0
80106ed7:	6a 00                	push   $0x0
  pushl $65
80106ed9:	6a 41                	push   $0x41
  jmp alltraps
80106edb:	e9 43 f7 ff ff       	jmp    80106623 <alltraps>

80106ee0 <vector66>:
.globl vector66
vector66:
  pushl $0
80106ee0:	6a 00                	push   $0x0
  pushl $66
80106ee2:	6a 42                	push   $0x42
  jmp alltraps
80106ee4:	e9 3a f7 ff ff       	jmp    80106623 <alltraps>

80106ee9 <vector67>:
.globl vector67
vector67:
  pushl $0
80106ee9:	6a 00                	push   $0x0
  pushl $67
80106eeb:	6a 43                	push   $0x43
  jmp alltraps
80106eed:	e9 31 f7 ff ff       	jmp    80106623 <alltraps>

80106ef2 <vector68>:
.globl vector68
vector68:
  pushl $0
80106ef2:	6a 00                	push   $0x0
  pushl $68
80106ef4:	6a 44                	push   $0x44
  jmp alltraps
80106ef6:	e9 28 f7 ff ff       	jmp    80106623 <alltraps>

80106efb <vector69>:
.globl vector69
vector69:
  pushl $0
80106efb:	6a 00                	push   $0x0
  pushl $69
80106efd:	6a 45                	push   $0x45
  jmp alltraps
80106eff:	e9 1f f7 ff ff       	jmp    80106623 <alltraps>

80106f04 <vector70>:
.globl vector70
vector70:
  pushl $0
80106f04:	6a 00                	push   $0x0
  pushl $70
80106f06:	6a 46                	push   $0x46
  jmp alltraps
80106f08:	e9 16 f7 ff ff       	jmp    80106623 <alltraps>

80106f0d <vector71>:
.globl vector71
vector71:
  pushl $0
80106f0d:	6a 00                	push   $0x0
  pushl $71
80106f0f:	6a 47                	push   $0x47
  jmp alltraps
80106f11:	e9 0d f7 ff ff       	jmp    80106623 <alltraps>

80106f16 <vector72>:
.globl vector72
vector72:
  pushl $0
80106f16:	6a 00                	push   $0x0
  pushl $72
80106f18:	6a 48                	push   $0x48
  jmp alltraps
80106f1a:	e9 04 f7 ff ff       	jmp    80106623 <alltraps>

80106f1f <vector73>:
.globl vector73
vector73:
  pushl $0
80106f1f:	6a 00                	push   $0x0
  pushl $73
80106f21:	6a 49                	push   $0x49
  jmp alltraps
80106f23:	e9 fb f6 ff ff       	jmp    80106623 <alltraps>

80106f28 <vector74>:
.globl vector74
vector74:
  pushl $0
80106f28:	6a 00                	push   $0x0
  pushl $74
80106f2a:	6a 4a                	push   $0x4a
  jmp alltraps
80106f2c:	e9 f2 f6 ff ff       	jmp    80106623 <alltraps>

80106f31 <vector75>:
.globl vector75
vector75:
  pushl $0
80106f31:	6a 00                	push   $0x0
  pushl $75
80106f33:	6a 4b                	push   $0x4b
  jmp alltraps
80106f35:	e9 e9 f6 ff ff       	jmp    80106623 <alltraps>

80106f3a <vector76>:
.globl vector76
vector76:
  pushl $0
80106f3a:	6a 00                	push   $0x0
  pushl $76
80106f3c:	6a 4c                	push   $0x4c
  jmp alltraps
80106f3e:	e9 e0 f6 ff ff       	jmp    80106623 <alltraps>

80106f43 <vector77>:
.globl vector77
vector77:
  pushl $0
80106f43:	6a 00                	push   $0x0
  pushl $77
80106f45:	6a 4d                	push   $0x4d
  jmp alltraps
80106f47:	e9 d7 f6 ff ff       	jmp    80106623 <alltraps>

80106f4c <vector78>:
.globl vector78
vector78:
  pushl $0
80106f4c:	6a 00                	push   $0x0
  pushl $78
80106f4e:	6a 4e                	push   $0x4e
  jmp alltraps
80106f50:	e9 ce f6 ff ff       	jmp    80106623 <alltraps>

80106f55 <vector79>:
.globl vector79
vector79:
  pushl $0
80106f55:	6a 00                	push   $0x0
  pushl $79
80106f57:	6a 4f                	push   $0x4f
  jmp alltraps
80106f59:	e9 c5 f6 ff ff       	jmp    80106623 <alltraps>

80106f5e <vector80>:
.globl vector80
vector80:
  pushl $0
80106f5e:	6a 00                	push   $0x0
  pushl $80
80106f60:	6a 50                	push   $0x50
  jmp alltraps
80106f62:	e9 bc f6 ff ff       	jmp    80106623 <alltraps>

80106f67 <vector81>:
.globl vector81
vector81:
  pushl $0
80106f67:	6a 00                	push   $0x0
  pushl $81
80106f69:	6a 51                	push   $0x51
  jmp alltraps
80106f6b:	e9 b3 f6 ff ff       	jmp    80106623 <alltraps>

80106f70 <vector82>:
.globl vector82
vector82:
  pushl $0
80106f70:	6a 00                	push   $0x0
  pushl $82
80106f72:	6a 52                	push   $0x52
  jmp alltraps
80106f74:	e9 aa f6 ff ff       	jmp    80106623 <alltraps>

80106f79 <vector83>:
.globl vector83
vector83:
  pushl $0
80106f79:	6a 00                	push   $0x0
  pushl $83
80106f7b:	6a 53                	push   $0x53
  jmp alltraps
80106f7d:	e9 a1 f6 ff ff       	jmp    80106623 <alltraps>

80106f82 <vector84>:
.globl vector84
vector84:
  pushl $0
80106f82:	6a 00                	push   $0x0
  pushl $84
80106f84:	6a 54                	push   $0x54
  jmp alltraps
80106f86:	e9 98 f6 ff ff       	jmp    80106623 <alltraps>

80106f8b <vector85>:
.globl vector85
vector85:
  pushl $0
80106f8b:	6a 00                	push   $0x0
  pushl $85
80106f8d:	6a 55                	push   $0x55
  jmp alltraps
80106f8f:	e9 8f f6 ff ff       	jmp    80106623 <alltraps>

80106f94 <vector86>:
.globl vector86
vector86:
  pushl $0
80106f94:	6a 00                	push   $0x0
  pushl $86
80106f96:	6a 56                	push   $0x56
  jmp alltraps
80106f98:	e9 86 f6 ff ff       	jmp    80106623 <alltraps>

80106f9d <vector87>:
.globl vector87
vector87:
  pushl $0
80106f9d:	6a 00                	push   $0x0
  pushl $87
80106f9f:	6a 57                	push   $0x57
  jmp alltraps
80106fa1:	e9 7d f6 ff ff       	jmp    80106623 <alltraps>

80106fa6 <vector88>:
.globl vector88
vector88:
  pushl $0
80106fa6:	6a 00                	push   $0x0
  pushl $88
80106fa8:	6a 58                	push   $0x58
  jmp alltraps
80106faa:	e9 74 f6 ff ff       	jmp    80106623 <alltraps>

80106faf <vector89>:
.globl vector89
vector89:
  pushl $0
80106faf:	6a 00                	push   $0x0
  pushl $89
80106fb1:	6a 59                	push   $0x59
  jmp alltraps
80106fb3:	e9 6b f6 ff ff       	jmp    80106623 <alltraps>

80106fb8 <vector90>:
.globl vector90
vector90:
  pushl $0
80106fb8:	6a 00                	push   $0x0
  pushl $90
80106fba:	6a 5a                	push   $0x5a
  jmp alltraps
80106fbc:	e9 62 f6 ff ff       	jmp    80106623 <alltraps>

80106fc1 <vector91>:
.globl vector91
vector91:
  pushl $0
80106fc1:	6a 00                	push   $0x0
  pushl $91
80106fc3:	6a 5b                	push   $0x5b
  jmp alltraps
80106fc5:	e9 59 f6 ff ff       	jmp    80106623 <alltraps>

80106fca <vector92>:
.globl vector92
vector92:
  pushl $0
80106fca:	6a 00                	push   $0x0
  pushl $92
80106fcc:	6a 5c                	push   $0x5c
  jmp alltraps
80106fce:	e9 50 f6 ff ff       	jmp    80106623 <alltraps>

80106fd3 <vector93>:
.globl vector93
vector93:
  pushl $0
80106fd3:	6a 00                	push   $0x0
  pushl $93
80106fd5:	6a 5d                	push   $0x5d
  jmp alltraps
80106fd7:	e9 47 f6 ff ff       	jmp    80106623 <alltraps>

80106fdc <vector94>:
.globl vector94
vector94:
  pushl $0
80106fdc:	6a 00                	push   $0x0
  pushl $94
80106fde:	6a 5e                	push   $0x5e
  jmp alltraps
80106fe0:	e9 3e f6 ff ff       	jmp    80106623 <alltraps>

80106fe5 <vector95>:
.globl vector95
vector95:
  pushl $0
80106fe5:	6a 00                	push   $0x0
  pushl $95
80106fe7:	6a 5f                	push   $0x5f
  jmp alltraps
80106fe9:	e9 35 f6 ff ff       	jmp    80106623 <alltraps>

80106fee <vector96>:
.globl vector96
vector96:
  pushl $0
80106fee:	6a 00                	push   $0x0
  pushl $96
80106ff0:	6a 60                	push   $0x60
  jmp alltraps
80106ff2:	e9 2c f6 ff ff       	jmp    80106623 <alltraps>

80106ff7 <vector97>:
.globl vector97
vector97:
  pushl $0
80106ff7:	6a 00                	push   $0x0
  pushl $97
80106ff9:	6a 61                	push   $0x61
  jmp alltraps
80106ffb:	e9 23 f6 ff ff       	jmp    80106623 <alltraps>

80107000 <vector98>:
.globl vector98
vector98:
  pushl $0
80107000:	6a 00                	push   $0x0
  pushl $98
80107002:	6a 62                	push   $0x62
  jmp alltraps
80107004:	e9 1a f6 ff ff       	jmp    80106623 <alltraps>

80107009 <vector99>:
.globl vector99
vector99:
  pushl $0
80107009:	6a 00                	push   $0x0
  pushl $99
8010700b:	6a 63                	push   $0x63
  jmp alltraps
8010700d:	e9 11 f6 ff ff       	jmp    80106623 <alltraps>

80107012 <vector100>:
.globl vector100
vector100:
  pushl $0
80107012:	6a 00                	push   $0x0
  pushl $100
80107014:	6a 64                	push   $0x64
  jmp alltraps
80107016:	e9 08 f6 ff ff       	jmp    80106623 <alltraps>

8010701b <vector101>:
.globl vector101
vector101:
  pushl $0
8010701b:	6a 00                	push   $0x0
  pushl $101
8010701d:	6a 65                	push   $0x65
  jmp alltraps
8010701f:	e9 ff f5 ff ff       	jmp    80106623 <alltraps>

80107024 <vector102>:
.globl vector102
vector102:
  pushl $0
80107024:	6a 00                	push   $0x0
  pushl $102
80107026:	6a 66                	push   $0x66
  jmp alltraps
80107028:	e9 f6 f5 ff ff       	jmp    80106623 <alltraps>

8010702d <vector103>:
.globl vector103
vector103:
  pushl $0
8010702d:	6a 00                	push   $0x0
  pushl $103
8010702f:	6a 67                	push   $0x67
  jmp alltraps
80107031:	e9 ed f5 ff ff       	jmp    80106623 <alltraps>

80107036 <vector104>:
.globl vector104
vector104:
  pushl $0
80107036:	6a 00                	push   $0x0
  pushl $104
80107038:	6a 68                	push   $0x68
  jmp alltraps
8010703a:	e9 e4 f5 ff ff       	jmp    80106623 <alltraps>

8010703f <vector105>:
.globl vector105
vector105:
  pushl $0
8010703f:	6a 00                	push   $0x0
  pushl $105
80107041:	6a 69                	push   $0x69
  jmp alltraps
80107043:	e9 db f5 ff ff       	jmp    80106623 <alltraps>

80107048 <vector106>:
.globl vector106
vector106:
  pushl $0
80107048:	6a 00                	push   $0x0
  pushl $106
8010704a:	6a 6a                	push   $0x6a
  jmp alltraps
8010704c:	e9 d2 f5 ff ff       	jmp    80106623 <alltraps>

80107051 <vector107>:
.globl vector107
vector107:
  pushl $0
80107051:	6a 00                	push   $0x0
  pushl $107
80107053:	6a 6b                	push   $0x6b
  jmp alltraps
80107055:	e9 c9 f5 ff ff       	jmp    80106623 <alltraps>

8010705a <vector108>:
.globl vector108
vector108:
  pushl $0
8010705a:	6a 00                	push   $0x0
  pushl $108
8010705c:	6a 6c                	push   $0x6c
  jmp alltraps
8010705e:	e9 c0 f5 ff ff       	jmp    80106623 <alltraps>

80107063 <vector109>:
.globl vector109
vector109:
  pushl $0
80107063:	6a 00                	push   $0x0
  pushl $109
80107065:	6a 6d                	push   $0x6d
  jmp alltraps
80107067:	e9 b7 f5 ff ff       	jmp    80106623 <alltraps>

8010706c <vector110>:
.globl vector110
vector110:
  pushl $0
8010706c:	6a 00                	push   $0x0
  pushl $110
8010706e:	6a 6e                	push   $0x6e
  jmp alltraps
80107070:	e9 ae f5 ff ff       	jmp    80106623 <alltraps>

80107075 <vector111>:
.globl vector111
vector111:
  pushl $0
80107075:	6a 00                	push   $0x0
  pushl $111
80107077:	6a 6f                	push   $0x6f
  jmp alltraps
80107079:	e9 a5 f5 ff ff       	jmp    80106623 <alltraps>

8010707e <vector112>:
.globl vector112
vector112:
  pushl $0
8010707e:	6a 00                	push   $0x0
  pushl $112
80107080:	6a 70                	push   $0x70
  jmp alltraps
80107082:	e9 9c f5 ff ff       	jmp    80106623 <alltraps>

80107087 <vector113>:
.globl vector113
vector113:
  pushl $0
80107087:	6a 00                	push   $0x0
  pushl $113
80107089:	6a 71                	push   $0x71
  jmp alltraps
8010708b:	e9 93 f5 ff ff       	jmp    80106623 <alltraps>

80107090 <vector114>:
.globl vector114
vector114:
  pushl $0
80107090:	6a 00                	push   $0x0
  pushl $114
80107092:	6a 72                	push   $0x72
  jmp alltraps
80107094:	e9 8a f5 ff ff       	jmp    80106623 <alltraps>

80107099 <vector115>:
.globl vector115
vector115:
  pushl $0
80107099:	6a 00                	push   $0x0
  pushl $115
8010709b:	6a 73                	push   $0x73
  jmp alltraps
8010709d:	e9 81 f5 ff ff       	jmp    80106623 <alltraps>

801070a2 <vector116>:
.globl vector116
vector116:
  pushl $0
801070a2:	6a 00                	push   $0x0
  pushl $116
801070a4:	6a 74                	push   $0x74
  jmp alltraps
801070a6:	e9 78 f5 ff ff       	jmp    80106623 <alltraps>

801070ab <vector117>:
.globl vector117
vector117:
  pushl $0
801070ab:	6a 00                	push   $0x0
  pushl $117
801070ad:	6a 75                	push   $0x75
  jmp alltraps
801070af:	e9 6f f5 ff ff       	jmp    80106623 <alltraps>

801070b4 <vector118>:
.globl vector118
vector118:
  pushl $0
801070b4:	6a 00                	push   $0x0
  pushl $118
801070b6:	6a 76                	push   $0x76
  jmp alltraps
801070b8:	e9 66 f5 ff ff       	jmp    80106623 <alltraps>

801070bd <vector119>:
.globl vector119
vector119:
  pushl $0
801070bd:	6a 00                	push   $0x0
  pushl $119
801070bf:	6a 77                	push   $0x77
  jmp alltraps
801070c1:	e9 5d f5 ff ff       	jmp    80106623 <alltraps>

801070c6 <vector120>:
.globl vector120
vector120:
  pushl $0
801070c6:	6a 00                	push   $0x0
  pushl $120
801070c8:	6a 78                	push   $0x78
  jmp alltraps
801070ca:	e9 54 f5 ff ff       	jmp    80106623 <alltraps>

801070cf <vector121>:
.globl vector121
vector121:
  pushl $0
801070cf:	6a 00                	push   $0x0
  pushl $121
801070d1:	6a 79                	push   $0x79
  jmp alltraps
801070d3:	e9 4b f5 ff ff       	jmp    80106623 <alltraps>

801070d8 <vector122>:
.globl vector122
vector122:
  pushl $0
801070d8:	6a 00                	push   $0x0
  pushl $122
801070da:	6a 7a                	push   $0x7a
  jmp alltraps
801070dc:	e9 42 f5 ff ff       	jmp    80106623 <alltraps>

801070e1 <vector123>:
.globl vector123
vector123:
  pushl $0
801070e1:	6a 00                	push   $0x0
  pushl $123
801070e3:	6a 7b                	push   $0x7b
  jmp alltraps
801070e5:	e9 39 f5 ff ff       	jmp    80106623 <alltraps>

801070ea <vector124>:
.globl vector124
vector124:
  pushl $0
801070ea:	6a 00                	push   $0x0
  pushl $124
801070ec:	6a 7c                	push   $0x7c
  jmp alltraps
801070ee:	e9 30 f5 ff ff       	jmp    80106623 <alltraps>

801070f3 <vector125>:
.globl vector125
vector125:
  pushl $0
801070f3:	6a 00                	push   $0x0
  pushl $125
801070f5:	6a 7d                	push   $0x7d
  jmp alltraps
801070f7:	e9 27 f5 ff ff       	jmp    80106623 <alltraps>

801070fc <vector126>:
.globl vector126
vector126:
  pushl $0
801070fc:	6a 00                	push   $0x0
  pushl $126
801070fe:	6a 7e                	push   $0x7e
  jmp alltraps
80107100:	e9 1e f5 ff ff       	jmp    80106623 <alltraps>

80107105 <vector127>:
.globl vector127
vector127:
  pushl $0
80107105:	6a 00                	push   $0x0
  pushl $127
80107107:	6a 7f                	push   $0x7f
  jmp alltraps
80107109:	e9 15 f5 ff ff       	jmp    80106623 <alltraps>

8010710e <vector128>:
.globl vector128
vector128:
  pushl $0
8010710e:	6a 00                	push   $0x0
  pushl $128
80107110:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107115:	e9 09 f5 ff ff       	jmp    80106623 <alltraps>

8010711a <vector129>:
.globl vector129
vector129:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $129
8010711c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107121:	e9 fd f4 ff ff       	jmp    80106623 <alltraps>

80107126 <vector130>:
.globl vector130
vector130:
  pushl $0
80107126:	6a 00                	push   $0x0
  pushl $130
80107128:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010712d:	e9 f1 f4 ff ff       	jmp    80106623 <alltraps>

80107132 <vector131>:
.globl vector131
vector131:
  pushl $0
80107132:	6a 00                	push   $0x0
  pushl $131
80107134:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107139:	e9 e5 f4 ff ff       	jmp    80106623 <alltraps>

8010713e <vector132>:
.globl vector132
vector132:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $132
80107140:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107145:	e9 d9 f4 ff ff       	jmp    80106623 <alltraps>

8010714a <vector133>:
.globl vector133
vector133:
  pushl $0
8010714a:	6a 00                	push   $0x0
  pushl $133
8010714c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107151:	e9 cd f4 ff ff       	jmp    80106623 <alltraps>

80107156 <vector134>:
.globl vector134
vector134:
  pushl $0
80107156:	6a 00                	push   $0x0
  pushl $134
80107158:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010715d:	e9 c1 f4 ff ff       	jmp    80106623 <alltraps>

80107162 <vector135>:
.globl vector135
vector135:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $135
80107164:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107169:	e9 b5 f4 ff ff       	jmp    80106623 <alltraps>

8010716e <vector136>:
.globl vector136
vector136:
  pushl $0
8010716e:	6a 00                	push   $0x0
  pushl $136
80107170:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107175:	e9 a9 f4 ff ff       	jmp    80106623 <alltraps>

8010717a <vector137>:
.globl vector137
vector137:
  pushl $0
8010717a:	6a 00                	push   $0x0
  pushl $137
8010717c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107181:	e9 9d f4 ff ff       	jmp    80106623 <alltraps>

80107186 <vector138>:
.globl vector138
vector138:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $138
80107188:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010718d:	e9 91 f4 ff ff       	jmp    80106623 <alltraps>

80107192 <vector139>:
.globl vector139
vector139:
  pushl $0
80107192:	6a 00                	push   $0x0
  pushl $139
80107194:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107199:	e9 85 f4 ff ff       	jmp    80106623 <alltraps>

8010719e <vector140>:
.globl vector140
vector140:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $140
801071a0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801071a5:	e9 79 f4 ff ff       	jmp    80106623 <alltraps>

801071aa <vector141>:
.globl vector141
vector141:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $141
801071ac:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801071b1:	e9 6d f4 ff ff       	jmp    80106623 <alltraps>

801071b6 <vector142>:
.globl vector142
vector142:
  pushl $0
801071b6:	6a 00                	push   $0x0
  pushl $142
801071b8:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801071bd:	e9 61 f4 ff ff       	jmp    80106623 <alltraps>

801071c2 <vector143>:
.globl vector143
vector143:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $143
801071c4:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801071c9:	e9 55 f4 ff ff       	jmp    80106623 <alltraps>

801071ce <vector144>:
.globl vector144
vector144:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $144
801071d0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801071d5:	e9 49 f4 ff ff       	jmp    80106623 <alltraps>

801071da <vector145>:
.globl vector145
vector145:
  pushl $0
801071da:	6a 00                	push   $0x0
  pushl $145
801071dc:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801071e1:	e9 3d f4 ff ff       	jmp    80106623 <alltraps>

801071e6 <vector146>:
.globl vector146
vector146:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $146
801071e8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801071ed:	e9 31 f4 ff ff       	jmp    80106623 <alltraps>

801071f2 <vector147>:
.globl vector147
vector147:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $147
801071f4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801071f9:	e9 25 f4 ff ff       	jmp    80106623 <alltraps>

801071fe <vector148>:
.globl vector148
vector148:
  pushl $0
801071fe:	6a 00                	push   $0x0
  pushl $148
80107200:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107205:	e9 19 f4 ff ff       	jmp    80106623 <alltraps>

8010720a <vector149>:
.globl vector149
vector149:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $149
8010720c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107211:	e9 0d f4 ff ff       	jmp    80106623 <alltraps>

80107216 <vector150>:
.globl vector150
vector150:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $150
80107218:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010721d:	e9 01 f4 ff ff       	jmp    80106623 <alltraps>

80107222 <vector151>:
.globl vector151
vector151:
  pushl $0
80107222:	6a 00                	push   $0x0
  pushl $151
80107224:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107229:	e9 f5 f3 ff ff       	jmp    80106623 <alltraps>

8010722e <vector152>:
.globl vector152
vector152:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $152
80107230:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107235:	e9 e9 f3 ff ff       	jmp    80106623 <alltraps>

8010723a <vector153>:
.globl vector153
vector153:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $153
8010723c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107241:	e9 dd f3 ff ff       	jmp    80106623 <alltraps>

80107246 <vector154>:
.globl vector154
vector154:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $154
80107248:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010724d:	e9 d1 f3 ff ff       	jmp    80106623 <alltraps>

80107252 <vector155>:
.globl vector155
vector155:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $155
80107254:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107259:	e9 c5 f3 ff ff       	jmp    80106623 <alltraps>

8010725e <vector156>:
.globl vector156
vector156:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $156
80107260:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107265:	e9 b9 f3 ff ff       	jmp    80106623 <alltraps>

8010726a <vector157>:
.globl vector157
vector157:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $157
8010726c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107271:	e9 ad f3 ff ff       	jmp    80106623 <alltraps>

80107276 <vector158>:
.globl vector158
vector158:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $158
80107278:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010727d:	e9 a1 f3 ff ff       	jmp    80106623 <alltraps>

80107282 <vector159>:
.globl vector159
vector159:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $159
80107284:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107289:	e9 95 f3 ff ff       	jmp    80106623 <alltraps>

8010728e <vector160>:
.globl vector160
vector160:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $160
80107290:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107295:	e9 89 f3 ff ff       	jmp    80106623 <alltraps>

8010729a <vector161>:
.globl vector161
vector161:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $161
8010729c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801072a1:	e9 7d f3 ff ff       	jmp    80106623 <alltraps>

801072a6 <vector162>:
.globl vector162
vector162:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $162
801072a8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801072ad:	e9 71 f3 ff ff       	jmp    80106623 <alltraps>

801072b2 <vector163>:
.globl vector163
vector163:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $163
801072b4:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801072b9:	e9 65 f3 ff ff       	jmp    80106623 <alltraps>

801072be <vector164>:
.globl vector164
vector164:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $164
801072c0:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801072c5:	e9 59 f3 ff ff       	jmp    80106623 <alltraps>

801072ca <vector165>:
.globl vector165
vector165:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $165
801072cc:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801072d1:	e9 4d f3 ff ff       	jmp    80106623 <alltraps>

801072d6 <vector166>:
.globl vector166
vector166:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $166
801072d8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801072dd:	e9 41 f3 ff ff       	jmp    80106623 <alltraps>

801072e2 <vector167>:
.globl vector167
vector167:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $167
801072e4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801072e9:	e9 35 f3 ff ff       	jmp    80106623 <alltraps>

801072ee <vector168>:
.globl vector168
vector168:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $168
801072f0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801072f5:	e9 29 f3 ff ff       	jmp    80106623 <alltraps>

801072fa <vector169>:
.globl vector169
vector169:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $169
801072fc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107301:	e9 1d f3 ff ff       	jmp    80106623 <alltraps>

80107306 <vector170>:
.globl vector170
vector170:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $170
80107308:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010730d:	e9 11 f3 ff ff       	jmp    80106623 <alltraps>

80107312 <vector171>:
.globl vector171
vector171:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $171
80107314:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107319:	e9 05 f3 ff ff       	jmp    80106623 <alltraps>

8010731e <vector172>:
.globl vector172
vector172:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $172
80107320:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107325:	e9 f9 f2 ff ff       	jmp    80106623 <alltraps>

8010732a <vector173>:
.globl vector173
vector173:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $173
8010732c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107331:	e9 ed f2 ff ff       	jmp    80106623 <alltraps>

80107336 <vector174>:
.globl vector174
vector174:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $174
80107338:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010733d:	e9 e1 f2 ff ff       	jmp    80106623 <alltraps>

80107342 <vector175>:
.globl vector175
vector175:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $175
80107344:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107349:	e9 d5 f2 ff ff       	jmp    80106623 <alltraps>

8010734e <vector176>:
.globl vector176
vector176:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $176
80107350:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107355:	e9 c9 f2 ff ff       	jmp    80106623 <alltraps>

8010735a <vector177>:
.globl vector177
vector177:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $177
8010735c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107361:	e9 bd f2 ff ff       	jmp    80106623 <alltraps>

80107366 <vector178>:
.globl vector178
vector178:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $178
80107368:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010736d:	e9 b1 f2 ff ff       	jmp    80106623 <alltraps>

80107372 <vector179>:
.globl vector179
vector179:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $179
80107374:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107379:	e9 a5 f2 ff ff       	jmp    80106623 <alltraps>

8010737e <vector180>:
.globl vector180
vector180:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $180
80107380:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107385:	e9 99 f2 ff ff       	jmp    80106623 <alltraps>

8010738a <vector181>:
.globl vector181
vector181:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $181
8010738c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107391:	e9 8d f2 ff ff       	jmp    80106623 <alltraps>

80107396 <vector182>:
.globl vector182
vector182:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $182
80107398:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010739d:	e9 81 f2 ff ff       	jmp    80106623 <alltraps>

801073a2 <vector183>:
.globl vector183
vector183:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $183
801073a4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801073a9:	e9 75 f2 ff ff       	jmp    80106623 <alltraps>

801073ae <vector184>:
.globl vector184
vector184:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $184
801073b0:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801073b5:	e9 69 f2 ff ff       	jmp    80106623 <alltraps>

801073ba <vector185>:
.globl vector185
vector185:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $185
801073bc:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801073c1:	e9 5d f2 ff ff       	jmp    80106623 <alltraps>

801073c6 <vector186>:
.globl vector186
vector186:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $186
801073c8:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801073cd:	e9 51 f2 ff ff       	jmp    80106623 <alltraps>

801073d2 <vector187>:
.globl vector187
vector187:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $187
801073d4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801073d9:	e9 45 f2 ff ff       	jmp    80106623 <alltraps>

801073de <vector188>:
.globl vector188
vector188:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $188
801073e0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801073e5:	e9 39 f2 ff ff       	jmp    80106623 <alltraps>

801073ea <vector189>:
.globl vector189
vector189:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $189
801073ec:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801073f1:	e9 2d f2 ff ff       	jmp    80106623 <alltraps>

801073f6 <vector190>:
.globl vector190
vector190:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $190
801073f8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801073fd:	e9 21 f2 ff ff       	jmp    80106623 <alltraps>

80107402 <vector191>:
.globl vector191
vector191:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $191
80107404:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107409:	e9 15 f2 ff ff       	jmp    80106623 <alltraps>

8010740e <vector192>:
.globl vector192
vector192:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $192
80107410:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107415:	e9 09 f2 ff ff       	jmp    80106623 <alltraps>

8010741a <vector193>:
.globl vector193
vector193:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $193
8010741c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107421:	e9 fd f1 ff ff       	jmp    80106623 <alltraps>

80107426 <vector194>:
.globl vector194
vector194:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $194
80107428:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010742d:	e9 f1 f1 ff ff       	jmp    80106623 <alltraps>

80107432 <vector195>:
.globl vector195
vector195:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $195
80107434:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107439:	e9 e5 f1 ff ff       	jmp    80106623 <alltraps>

8010743e <vector196>:
.globl vector196
vector196:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $196
80107440:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107445:	e9 d9 f1 ff ff       	jmp    80106623 <alltraps>

8010744a <vector197>:
.globl vector197
vector197:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $197
8010744c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107451:	e9 cd f1 ff ff       	jmp    80106623 <alltraps>

80107456 <vector198>:
.globl vector198
vector198:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $198
80107458:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010745d:	e9 c1 f1 ff ff       	jmp    80106623 <alltraps>

80107462 <vector199>:
.globl vector199
vector199:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $199
80107464:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107469:	e9 b5 f1 ff ff       	jmp    80106623 <alltraps>

8010746e <vector200>:
.globl vector200
vector200:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $200
80107470:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107475:	e9 a9 f1 ff ff       	jmp    80106623 <alltraps>

8010747a <vector201>:
.globl vector201
vector201:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $201
8010747c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107481:	e9 9d f1 ff ff       	jmp    80106623 <alltraps>

80107486 <vector202>:
.globl vector202
vector202:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $202
80107488:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
8010748d:	e9 91 f1 ff ff       	jmp    80106623 <alltraps>

80107492 <vector203>:
.globl vector203
vector203:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $203
80107494:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107499:	e9 85 f1 ff ff       	jmp    80106623 <alltraps>

8010749e <vector204>:
.globl vector204
vector204:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $204
801074a0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801074a5:	e9 79 f1 ff ff       	jmp    80106623 <alltraps>

801074aa <vector205>:
.globl vector205
vector205:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $205
801074ac:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801074b1:	e9 6d f1 ff ff       	jmp    80106623 <alltraps>

801074b6 <vector206>:
.globl vector206
vector206:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $206
801074b8:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801074bd:	e9 61 f1 ff ff       	jmp    80106623 <alltraps>

801074c2 <vector207>:
.globl vector207
vector207:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $207
801074c4:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801074c9:	e9 55 f1 ff ff       	jmp    80106623 <alltraps>

801074ce <vector208>:
.globl vector208
vector208:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $208
801074d0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801074d5:	e9 49 f1 ff ff       	jmp    80106623 <alltraps>

801074da <vector209>:
.globl vector209
vector209:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $209
801074dc:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801074e1:	e9 3d f1 ff ff       	jmp    80106623 <alltraps>

801074e6 <vector210>:
.globl vector210
vector210:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $210
801074e8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801074ed:	e9 31 f1 ff ff       	jmp    80106623 <alltraps>

801074f2 <vector211>:
.globl vector211
vector211:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $211
801074f4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801074f9:	e9 25 f1 ff ff       	jmp    80106623 <alltraps>

801074fe <vector212>:
.globl vector212
vector212:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $212
80107500:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107505:	e9 19 f1 ff ff       	jmp    80106623 <alltraps>

8010750a <vector213>:
.globl vector213
vector213:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $213
8010750c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107511:	e9 0d f1 ff ff       	jmp    80106623 <alltraps>

80107516 <vector214>:
.globl vector214
vector214:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $214
80107518:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010751d:	e9 01 f1 ff ff       	jmp    80106623 <alltraps>

80107522 <vector215>:
.globl vector215
vector215:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $215
80107524:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107529:	e9 f5 f0 ff ff       	jmp    80106623 <alltraps>

8010752e <vector216>:
.globl vector216
vector216:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $216
80107530:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107535:	e9 e9 f0 ff ff       	jmp    80106623 <alltraps>

8010753a <vector217>:
.globl vector217
vector217:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $217
8010753c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107541:	e9 dd f0 ff ff       	jmp    80106623 <alltraps>

80107546 <vector218>:
.globl vector218
vector218:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $218
80107548:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010754d:	e9 d1 f0 ff ff       	jmp    80106623 <alltraps>

80107552 <vector219>:
.globl vector219
vector219:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $219
80107554:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107559:	e9 c5 f0 ff ff       	jmp    80106623 <alltraps>

8010755e <vector220>:
.globl vector220
vector220:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $220
80107560:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107565:	e9 b9 f0 ff ff       	jmp    80106623 <alltraps>

8010756a <vector221>:
.globl vector221
vector221:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $221
8010756c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107571:	e9 ad f0 ff ff       	jmp    80106623 <alltraps>

80107576 <vector222>:
.globl vector222
vector222:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $222
80107578:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010757d:	e9 a1 f0 ff ff       	jmp    80106623 <alltraps>

80107582 <vector223>:
.globl vector223
vector223:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $223
80107584:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107589:	e9 95 f0 ff ff       	jmp    80106623 <alltraps>

8010758e <vector224>:
.globl vector224
vector224:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $224
80107590:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107595:	e9 89 f0 ff ff       	jmp    80106623 <alltraps>

8010759a <vector225>:
.globl vector225
vector225:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $225
8010759c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801075a1:	e9 7d f0 ff ff       	jmp    80106623 <alltraps>

801075a6 <vector226>:
.globl vector226
vector226:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $226
801075a8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801075ad:	e9 71 f0 ff ff       	jmp    80106623 <alltraps>

801075b2 <vector227>:
.globl vector227
vector227:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $227
801075b4:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801075b9:	e9 65 f0 ff ff       	jmp    80106623 <alltraps>

801075be <vector228>:
.globl vector228
vector228:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $228
801075c0:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801075c5:	e9 59 f0 ff ff       	jmp    80106623 <alltraps>

801075ca <vector229>:
.globl vector229
vector229:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $229
801075cc:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801075d1:	e9 4d f0 ff ff       	jmp    80106623 <alltraps>

801075d6 <vector230>:
.globl vector230
vector230:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $230
801075d8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801075dd:	e9 41 f0 ff ff       	jmp    80106623 <alltraps>

801075e2 <vector231>:
.globl vector231
vector231:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $231
801075e4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801075e9:	e9 35 f0 ff ff       	jmp    80106623 <alltraps>

801075ee <vector232>:
.globl vector232
vector232:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $232
801075f0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801075f5:	e9 29 f0 ff ff       	jmp    80106623 <alltraps>

801075fa <vector233>:
.globl vector233
vector233:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $233
801075fc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107601:	e9 1d f0 ff ff       	jmp    80106623 <alltraps>

80107606 <vector234>:
.globl vector234
vector234:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $234
80107608:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010760d:	e9 11 f0 ff ff       	jmp    80106623 <alltraps>

80107612 <vector235>:
.globl vector235
vector235:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $235
80107614:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107619:	e9 05 f0 ff ff       	jmp    80106623 <alltraps>

8010761e <vector236>:
.globl vector236
vector236:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $236
80107620:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107625:	e9 f9 ef ff ff       	jmp    80106623 <alltraps>

8010762a <vector237>:
.globl vector237
vector237:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $237
8010762c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107631:	e9 ed ef ff ff       	jmp    80106623 <alltraps>

80107636 <vector238>:
.globl vector238
vector238:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $238
80107638:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010763d:	e9 e1 ef ff ff       	jmp    80106623 <alltraps>

80107642 <vector239>:
.globl vector239
vector239:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $239
80107644:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107649:	e9 d5 ef ff ff       	jmp    80106623 <alltraps>

8010764e <vector240>:
.globl vector240
vector240:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $240
80107650:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107655:	e9 c9 ef ff ff       	jmp    80106623 <alltraps>

8010765a <vector241>:
.globl vector241
vector241:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $241
8010765c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107661:	e9 bd ef ff ff       	jmp    80106623 <alltraps>

80107666 <vector242>:
.globl vector242
vector242:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $242
80107668:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010766d:	e9 b1 ef ff ff       	jmp    80106623 <alltraps>

80107672 <vector243>:
.globl vector243
vector243:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $243
80107674:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107679:	e9 a5 ef ff ff       	jmp    80106623 <alltraps>

8010767e <vector244>:
.globl vector244
vector244:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $244
80107680:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107685:	e9 99 ef ff ff       	jmp    80106623 <alltraps>

8010768a <vector245>:
.globl vector245
vector245:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $245
8010768c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107691:	e9 8d ef ff ff       	jmp    80106623 <alltraps>

80107696 <vector246>:
.globl vector246
vector246:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $246
80107698:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010769d:	e9 81 ef ff ff       	jmp    80106623 <alltraps>

801076a2 <vector247>:
.globl vector247
vector247:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $247
801076a4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801076a9:	e9 75 ef ff ff       	jmp    80106623 <alltraps>

801076ae <vector248>:
.globl vector248
vector248:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $248
801076b0:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801076b5:	e9 69 ef ff ff       	jmp    80106623 <alltraps>

801076ba <vector249>:
.globl vector249
vector249:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $249
801076bc:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801076c1:	e9 5d ef ff ff       	jmp    80106623 <alltraps>

801076c6 <vector250>:
.globl vector250
vector250:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $250
801076c8:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801076cd:	e9 51 ef ff ff       	jmp    80106623 <alltraps>

801076d2 <vector251>:
.globl vector251
vector251:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $251
801076d4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801076d9:	e9 45 ef ff ff       	jmp    80106623 <alltraps>

801076de <vector252>:
.globl vector252
vector252:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $252
801076e0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801076e5:	e9 39 ef ff ff       	jmp    80106623 <alltraps>

801076ea <vector253>:
.globl vector253
vector253:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $253
801076ec:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801076f1:	e9 2d ef ff ff       	jmp    80106623 <alltraps>

801076f6 <vector254>:
.globl vector254
vector254:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $254
801076f8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801076fd:	e9 21 ef ff ff       	jmp    80106623 <alltraps>

80107702 <vector255>:
.globl vector255
vector255:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $255
80107704:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107709:	e9 15 ef ff ff       	jmp    80106623 <alltraps>

8010770e <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010770e:	55                   	push   %ebp
8010770f:	89 e5                	mov    %esp,%ebp
80107711:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107714:	8b 45 0c             	mov    0xc(%ebp),%eax
80107717:	83 e8 01             	sub    $0x1,%eax
8010771a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010771e:	8b 45 08             	mov    0x8(%ebp),%eax
80107721:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107725:	8b 45 08             	mov    0x8(%ebp),%eax
80107728:	c1 e8 10             	shr    $0x10,%eax
8010772b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010772f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107732:	0f 01 10             	lgdtl  (%eax)
}
80107735:	c9                   	leave  
80107736:	c3                   	ret    

80107737 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107737:	55                   	push   %ebp
80107738:	89 e5                	mov    %esp,%ebp
8010773a:	83 ec 04             	sub    $0x4,%esp
8010773d:	8b 45 08             	mov    0x8(%ebp),%eax
80107740:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107744:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107748:	0f 00 d8             	ltr    %ax
}
8010774b:	c9                   	leave  
8010774c:	c3                   	ret    

8010774d <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010774d:	55                   	push   %ebp
8010774e:	89 e5                	mov    %esp,%ebp
80107750:	83 ec 04             	sub    $0x4,%esp
80107753:	8b 45 08             	mov    0x8(%ebp),%eax
80107756:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
8010775a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010775e:	8e e8                	mov    %eax,%gs
}
80107760:	c9                   	leave  
80107761:	c3                   	ret    

80107762 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107762:	55                   	push   %ebp
80107763:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107765:	8b 45 08             	mov    0x8(%ebp),%eax
80107768:	0f 22 d8             	mov    %eax,%cr3
}
8010776b:	5d                   	pop    %ebp
8010776c:	c3                   	ret    

8010776d <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010776d:	55                   	push   %ebp
8010776e:	89 e5                	mov    %esp,%ebp
80107770:	8b 45 08             	mov    0x8(%ebp),%eax
80107773:	05 00 00 00 80       	add    $0x80000000,%eax
80107778:	5d                   	pop    %ebp
80107779:	c3                   	ret    

8010777a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010777a:	55                   	push   %ebp
8010777b:	89 e5                	mov    %esp,%ebp
8010777d:	8b 45 08             	mov    0x8(%ebp),%eax
80107780:	05 00 00 00 80       	add    $0x80000000,%eax
80107785:	5d                   	pop    %ebp
80107786:	c3                   	ret    

80107787 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107787:	55                   	push   %ebp
80107788:	89 e5                	mov    %esp,%ebp
8010778a:	53                   	push   %ebx
8010778b:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010778e:	e8 d2 b8 ff ff       	call   80103065 <cpunum>
80107793:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107799:	05 60 23 11 80       	add    $0x80112360,%eax
8010779e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801077a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a4:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801077aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ad:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801077b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b6:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801077ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077bd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077c1:	83 e2 f0             	and    $0xfffffff0,%edx
801077c4:	83 ca 0a             	or     $0xa,%edx
801077c7:	88 50 7d             	mov    %dl,0x7d(%eax)
801077ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077cd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077d1:	83 ca 10             	or     $0x10,%edx
801077d4:	88 50 7d             	mov    %dl,0x7d(%eax)
801077d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077da:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077de:	83 e2 9f             	and    $0xffffff9f,%edx
801077e1:	88 50 7d             	mov    %dl,0x7d(%eax)
801077e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077eb:	83 ca 80             	or     $0xffffff80,%edx
801077ee:	88 50 7d             	mov    %dl,0x7d(%eax)
801077f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801077f8:	83 ca 0f             	or     $0xf,%edx
801077fb:	88 50 7e             	mov    %dl,0x7e(%eax)
801077fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107801:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107805:	83 e2 ef             	and    $0xffffffef,%edx
80107808:	88 50 7e             	mov    %dl,0x7e(%eax)
8010780b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107812:	83 e2 df             	and    $0xffffffdf,%edx
80107815:	88 50 7e             	mov    %dl,0x7e(%eax)
80107818:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010781f:	83 ca 40             	or     $0x40,%edx
80107822:	88 50 7e             	mov    %dl,0x7e(%eax)
80107825:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107828:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010782c:	83 ca 80             	or     $0xffffff80,%edx
8010782f:	88 50 7e             	mov    %dl,0x7e(%eax)
80107832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107835:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010783c:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107843:	ff ff 
80107845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107848:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010784f:	00 00 
80107851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107854:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010785b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107865:	83 e2 f0             	and    $0xfffffff0,%edx
80107868:	83 ca 02             	or     $0x2,%edx
8010786b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107874:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010787b:	83 ca 10             	or     $0x10,%edx
8010787e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107884:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107887:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010788e:	83 e2 9f             	and    $0xffffff9f,%edx
80107891:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010789a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078a1:	83 ca 80             	or     $0xffffff80,%edx
801078a4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ad:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078b4:	83 ca 0f             	or     $0xf,%edx
801078b7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078c7:	83 e2 ef             	and    $0xffffffef,%edx
801078ca:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078da:	83 e2 df             	and    $0xffffffdf,%edx
801078dd:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078ed:	83 ca 40             	or     $0x40,%edx
801078f0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107900:	83 ca 80             	or     $0xffffff80,%edx
80107903:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010790c:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107916:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010791d:	ff ff 
8010791f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107922:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107929:	00 00 
8010792b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010792e:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107938:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010793f:	83 e2 f0             	and    $0xfffffff0,%edx
80107942:	83 ca 0a             	or     $0xa,%edx
80107945:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010794b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107955:	83 ca 10             	or     $0x10,%edx
80107958:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010795e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107961:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107968:	83 ca 60             	or     $0x60,%edx
8010796b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107974:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010797b:	83 ca 80             	or     $0xffffff80,%edx
8010797e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107987:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010798e:	83 ca 0f             	or     $0xf,%edx
80107991:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079a1:	83 e2 ef             	and    $0xffffffef,%edx
801079a4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ad:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079b4:	83 e2 df             	and    $0xffffffdf,%edx
801079b7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079c7:	83 ca 40             	or     $0x40,%edx
801079ca:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079da:	83 ca 80             	or     $0xffffff80,%edx
801079dd:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e6:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801079ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079f0:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801079f7:	ff ff 
801079f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fc:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107a03:	00 00 
80107a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a08:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a12:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a19:	83 e2 f0             	and    $0xfffffff0,%edx
80107a1c:	83 ca 02             	or     $0x2,%edx
80107a1f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a28:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a2f:	83 ca 10             	or     $0x10,%edx
80107a32:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a42:	83 ca 60             	or     $0x60,%edx
80107a45:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a55:	83 ca 80             	or     $0xffffff80,%edx
80107a58:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a61:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a68:	83 ca 0f             	or     $0xf,%edx
80107a6b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a74:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a7b:	83 e2 ef             	and    $0xffffffef,%edx
80107a7e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107a84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a87:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a8e:	83 e2 df             	and    $0xffffffdf,%edx
80107a91:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107aa1:	83 ca 40             	or     $0x40,%edx
80107aa4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aad:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ab4:	83 ca 80             	or     $0xffffff80,%edx
80107ab7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107abd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac0:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107ac7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aca:	05 b4 00 00 00       	add    $0xb4,%eax
80107acf:	89 c3                	mov    %eax,%ebx
80107ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad4:	05 b4 00 00 00       	add    $0xb4,%eax
80107ad9:	c1 e8 10             	shr    $0x10,%eax
80107adc:	89 c1                	mov    %eax,%ecx
80107ade:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae1:	05 b4 00 00 00       	add    $0xb4,%eax
80107ae6:	c1 e8 18             	shr    $0x18,%eax
80107ae9:	89 c2                	mov    %eax,%edx
80107aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aee:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107af5:	00 00 
80107af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afa:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107b01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b04:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107b0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b0d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b14:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b17:	83 c9 02             	or     $0x2,%ecx
80107b1a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b23:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b2a:	83 c9 10             	or     $0x10,%ecx
80107b2d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b36:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b3d:	83 e1 9f             	and    $0xffffff9f,%ecx
80107b40:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b49:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b50:	83 c9 80             	or     $0xffffff80,%ecx
80107b53:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b5c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b63:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b66:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b6f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b76:	83 e1 ef             	and    $0xffffffef,%ecx
80107b79:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b82:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b89:	83 e1 df             	and    $0xffffffdf,%ecx
80107b8c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b95:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b9c:	83 c9 40             	or     $0x40,%ecx
80107b9f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107baf:	83 c9 80             	or     $0xffffff80,%ecx
80107bb2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bbb:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc4:	83 c0 70             	add    $0x70,%eax
80107bc7:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107bce:	00 
80107bcf:	89 04 24             	mov    %eax,(%esp)
80107bd2:	e8 37 fb ff ff       	call   8010770e <lgdt>
  loadgs(SEG_KCPU << 3);
80107bd7:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107bde:	e8 6a fb ff ff       	call   8010774d <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107be6:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107bec:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107bf3:	00 00 00 00 
}
80107bf7:	83 c4 24             	add    $0x24,%esp
80107bfa:	5b                   	pop    %ebx
80107bfb:	5d                   	pop    %ebp
80107bfc:	c3                   	ret    

80107bfd <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107bfd:	55                   	push   %ebp
80107bfe:	89 e5                	mov    %esp,%ebp
80107c00:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107c03:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c06:	c1 e8 16             	shr    $0x16,%eax
80107c09:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107c10:	8b 45 08             	mov    0x8(%ebp),%eax
80107c13:	01 d0                	add    %edx,%eax
80107c15:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107c18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c1b:	8b 00                	mov    (%eax),%eax
80107c1d:	83 e0 01             	and    $0x1,%eax
80107c20:	85 c0                	test   %eax,%eax
80107c22:	74 17                	je     80107c3b <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107c24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c27:	8b 00                	mov    (%eax),%eax
80107c29:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107c2e:	89 04 24             	mov    %eax,(%esp)
80107c31:	e8 44 fb ff ff       	call   8010777a <p2v>
80107c36:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c39:	eb 4b                	jmp    80107c86 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107c3b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107c3f:	74 0e                	je     80107c4f <walkpgdir+0x52>
80107c41:	e8 89 b0 ff ff       	call   80102ccf <kalloc>
80107c46:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107c4d:	75 07                	jne    80107c56 <walkpgdir+0x59>
      return 0;
80107c4f:	b8 00 00 00 00       	mov    $0x0,%eax
80107c54:	eb 47                	jmp    80107c9d <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107c56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c5d:	00 
80107c5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c65:	00 
80107c66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c69:	89 04 24             	mov    %eax,(%esp)
80107c6c:	e8 be d5 ff ff       	call   8010522f <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107c71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c74:	89 04 24             	mov    %eax,(%esp)
80107c77:	e8 f1 fa ff ff       	call   8010776d <v2p>
80107c7c:	83 c8 07             	or     $0x7,%eax
80107c7f:	89 c2                	mov    %eax,%edx
80107c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c84:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107c86:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c89:	c1 e8 0c             	shr    $0xc,%eax
80107c8c:	25 ff 03 00 00       	and    $0x3ff,%eax
80107c91:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9b:	01 d0                	add    %edx,%eax
}
80107c9d:	c9                   	leave  
80107c9e:	c3                   	ret    

80107c9f <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107c9f:	55                   	push   %ebp
80107ca0:	89 e5                	mov    %esp,%ebp
80107ca2:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107ca5:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ca8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107cad:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107cb0:	8b 55 0c             	mov    0xc(%ebp),%edx
80107cb3:	8b 45 10             	mov    0x10(%ebp),%eax
80107cb6:	01 d0                	add    %edx,%eax
80107cb8:	83 e8 01             	sub    $0x1,%eax
80107cbb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107cc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107cc3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107cca:	00 
80107ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cce:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80107cd5:	89 04 24             	mov    %eax,(%esp)
80107cd8:	e8 20 ff ff ff       	call   80107bfd <walkpgdir>
80107cdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107ce0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ce4:	75 07                	jne    80107ced <mappages+0x4e>
      return -1;
80107ce6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107ceb:	eb 48                	jmp    80107d35 <mappages+0x96>
    if(*pte & PTE_P)
80107ced:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107cf0:	8b 00                	mov    (%eax),%eax
80107cf2:	83 e0 01             	and    $0x1,%eax
80107cf5:	85 c0                	test   %eax,%eax
80107cf7:	74 0c                	je     80107d05 <mappages+0x66>
      panic("remap");
80107cf9:	c7 04 24 a4 8b 10 80 	movl   $0x80108ba4,(%esp)
80107d00:	e8 35 88 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107d05:	8b 45 18             	mov    0x18(%ebp),%eax
80107d08:	0b 45 14             	or     0x14(%ebp),%eax
80107d0b:	83 c8 01             	or     $0x1,%eax
80107d0e:	89 c2                	mov    %eax,%edx
80107d10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d13:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107d15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d18:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d1b:	75 08                	jne    80107d25 <mappages+0x86>
      break;
80107d1d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107d1e:	b8 00 00 00 00       	mov    $0x0,%eax
80107d23:	eb 10                	jmp    80107d35 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107d25:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107d2c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107d33:	eb 8e                	jmp    80107cc3 <mappages+0x24>
  return 0;
}
80107d35:	c9                   	leave  
80107d36:	c3                   	ret    

80107d37 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107d37:	55                   	push   %ebp
80107d38:	89 e5                	mov    %esp,%ebp
80107d3a:	53                   	push   %ebx
80107d3b:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107d3e:	e8 8c af ff ff       	call   80102ccf <kalloc>
80107d43:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107d46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107d4a:	75 0a                	jne    80107d56 <setupkvm+0x1f>
    return 0;
80107d4c:	b8 00 00 00 00       	mov    $0x0,%eax
80107d51:	e9 98 00 00 00       	jmp    80107dee <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107d56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d5d:	00 
80107d5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d65:	00 
80107d66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d69:	89 04 24             	mov    %eax,(%esp)
80107d6c:	e8 be d4 ff ff       	call   8010522f <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107d71:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107d78:	e8 fd f9 ff ff       	call   8010777a <p2v>
80107d7d:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107d82:	76 0c                	jbe    80107d90 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107d84:	c7 04 24 aa 8b 10 80 	movl   $0x80108baa,(%esp)
80107d8b:	e8 aa 87 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107d90:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107d97:	eb 49                	jmp    80107de2 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d9c:	8b 48 0c             	mov    0xc(%eax),%ecx
80107d9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da2:	8b 50 04             	mov    0x4(%eax),%edx
80107da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da8:	8b 58 08             	mov    0x8(%eax),%ebx
80107dab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dae:	8b 40 04             	mov    0x4(%eax),%eax
80107db1:	29 c3                	sub    %eax,%ebx
80107db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db6:	8b 00                	mov    (%eax),%eax
80107db8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107dbc:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107dc0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107dc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107dcb:	89 04 24             	mov    %eax,(%esp)
80107dce:	e8 cc fe ff ff       	call   80107c9f <mappages>
80107dd3:	85 c0                	test   %eax,%eax
80107dd5:	79 07                	jns    80107dde <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107dd7:	b8 00 00 00 00       	mov    $0x0,%eax
80107ddc:	eb 10                	jmp    80107dee <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107dde:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107de2:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107de9:	72 ae                	jb     80107d99 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107deb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107dee:	83 c4 34             	add    $0x34,%esp
80107df1:	5b                   	pop    %ebx
80107df2:	5d                   	pop    %ebp
80107df3:	c3                   	ret    

80107df4 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107df4:	55                   	push   %ebp
80107df5:	89 e5                	mov    %esp,%ebp
80107df7:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107dfa:	e8 38 ff ff ff       	call   80107d37 <setupkvm>
80107dff:	a3 38 51 11 80       	mov    %eax,0x80115138
  switchkvm();
80107e04:	e8 02 00 00 00       	call   80107e0b <switchkvm>
}
80107e09:	c9                   	leave  
80107e0a:	c3                   	ret    

80107e0b <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107e0b:	55                   	push   %ebp
80107e0c:	89 e5                	mov    %esp,%ebp
80107e0e:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107e11:	a1 38 51 11 80       	mov    0x80115138,%eax
80107e16:	89 04 24             	mov    %eax,(%esp)
80107e19:	e8 4f f9 ff ff       	call   8010776d <v2p>
80107e1e:	89 04 24             	mov    %eax,(%esp)
80107e21:	e8 3c f9 ff ff       	call   80107762 <lcr3>
}
80107e26:	c9                   	leave  
80107e27:	c3                   	ret    

80107e28 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107e28:	55                   	push   %ebp
80107e29:	89 e5                	mov    %esp,%ebp
80107e2b:	53                   	push   %ebx
80107e2c:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107e2f:	e8 fb d2 ff ff       	call   8010512f <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107e34:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e3a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e41:	83 c2 08             	add    $0x8,%edx
80107e44:	89 d3                	mov    %edx,%ebx
80107e46:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e4d:	83 c2 08             	add    $0x8,%edx
80107e50:	c1 ea 10             	shr    $0x10,%edx
80107e53:	89 d1                	mov    %edx,%ecx
80107e55:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e5c:	83 c2 08             	add    $0x8,%edx
80107e5f:	c1 ea 18             	shr    $0x18,%edx
80107e62:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107e69:	67 00 
80107e6b:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107e72:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107e78:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107e7f:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e82:	83 c9 09             	or     $0x9,%ecx
80107e85:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107e8b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107e92:	83 c9 10             	or     $0x10,%ecx
80107e95:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107e9b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ea2:	83 e1 9f             	and    $0xffffff9f,%ecx
80107ea5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107eab:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107eb2:	83 c9 80             	or     $0xffffff80,%ecx
80107eb5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ebb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ec2:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ec5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ecb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ed2:	83 e1 ef             	and    $0xffffffef,%ecx
80107ed5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107edb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ee2:	83 e1 df             	and    $0xffffffdf,%ecx
80107ee5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107eeb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ef2:	83 c9 40             	or     $0x40,%ecx
80107ef5:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107efb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f02:	83 e1 7f             	and    $0x7f,%ecx
80107f05:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f0b:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107f11:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f17:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107f1e:	83 e2 ef             	and    $0xffffffef,%edx
80107f21:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107f27:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f2d:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107f33:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f39:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107f40:	8b 52 08             	mov    0x8(%edx),%edx
80107f43:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107f49:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107f4c:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107f53:	e8 df f7 ff ff       	call   80107737 <ltr>
  if(p->pgdir == 0)
80107f58:	8b 45 08             	mov    0x8(%ebp),%eax
80107f5b:	8b 40 04             	mov    0x4(%eax),%eax
80107f5e:	85 c0                	test   %eax,%eax
80107f60:	75 0c                	jne    80107f6e <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107f62:	c7 04 24 bb 8b 10 80 	movl   $0x80108bbb,(%esp)
80107f69:	e8 cc 85 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107f6e:	8b 45 08             	mov    0x8(%ebp),%eax
80107f71:	8b 40 04             	mov    0x4(%eax),%eax
80107f74:	89 04 24             	mov    %eax,(%esp)
80107f77:	e8 f1 f7 ff ff       	call   8010776d <v2p>
80107f7c:	89 04 24             	mov    %eax,(%esp)
80107f7f:	e8 de f7 ff ff       	call   80107762 <lcr3>
  popcli();
80107f84:	e8 ea d1 ff ff       	call   80105173 <popcli>
}
80107f89:	83 c4 14             	add    $0x14,%esp
80107f8c:	5b                   	pop    %ebx
80107f8d:	5d                   	pop    %ebp
80107f8e:	c3                   	ret    

80107f8f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107f8f:	55                   	push   %ebp
80107f90:	89 e5                	mov    %esp,%ebp
80107f92:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107f95:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107f9c:	76 0c                	jbe    80107faa <inituvm+0x1b>
    panic("inituvm: more than a page");
80107f9e:	c7 04 24 cf 8b 10 80 	movl   $0x80108bcf,(%esp)
80107fa5:	e8 90 85 ff ff       	call   8010053a <panic>
  mem = kalloc();
80107faa:	e8 20 ad ff ff       	call   80102ccf <kalloc>
80107faf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107fb2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fb9:	00 
80107fba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107fc1:	00 
80107fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc5:	89 04 24             	mov    %eax,(%esp)
80107fc8:	e8 62 d2 ff ff       	call   8010522f <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fd0:	89 04 24             	mov    %eax,(%esp)
80107fd3:	e8 95 f7 ff ff       	call   8010776d <v2p>
80107fd8:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107fdf:	00 
80107fe0:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107fe4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107feb:	00 
80107fec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ff3:	00 
80107ff4:	8b 45 08             	mov    0x8(%ebp),%eax
80107ff7:	89 04 24             	mov    %eax,(%esp)
80107ffa:	e8 a0 fc ff ff       	call   80107c9f <mappages>
  memmove(mem, init, sz);
80107fff:	8b 45 10             	mov    0x10(%ebp),%eax
80108002:	89 44 24 08          	mov    %eax,0x8(%esp)
80108006:	8b 45 0c             	mov    0xc(%ebp),%eax
80108009:	89 44 24 04          	mov    %eax,0x4(%esp)
8010800d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108010:	89 04 24             	mov    %eax,(%esp)
80108013:	e8 e6 d2 ff ff       	call   801052fe <memmove>
}
80108018:	c9                   	leave  
80108019:	c3                   	ret    

8010801a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010801a:	55                   	push   %ebp
8010801b:	89 e5                	mov    %esp,%ebp
8010801d:	53                   	push   %ebx
8010801e:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108021:	8b 45 0c             	mov    0xc(%ebp),%eax
80108024:	25 ff 0f 00 00       	and    $0xfff,%eax
80108029:	85 c0                	test   %eax,%eax
8010802b:	74 0c                	je     80108039 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010802d:	c7 04 24 ec 8b 10 80 	movl   $0x80108bec,(%esp)
80108034:	e8 01 85 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108039:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108040:	e9 a9 00 00 00       	jmp    801080ee <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108048:	8b 55 0c             	mov    0xc(%ebp),%edx
8010804b:	01 d0                	add    %edx,%eax
8010804d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108054:	00 
80108055:	89 44 24 04          	mov    %eax,0x4(%esp)
80108059:	8b 45 08             	mov    0x8(%ebp),%eax
8010805c:	89 04 24             	mov    %eax,(%esp)
8010805f:	e8 99 fb ff ff       	call   80107bfd <walkpgdir>
80108064:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108067:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010806b:	75 0c                	jne    80108079 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010806d:	c7 04 24 0f 8c 10 80 	movl   $0x80108c0f,(%esp)
80108074:	e8 c1 84 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108079:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010807c:	8b 00                	mov    (%eax),%eax
8010807e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108083:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108089:	8b 55 18             	mov    0x18(%ebp),%edx
8010808c:	29 c2                	sub    %eax,%edx
8010808e:	89 d0                	mov    %edx,%eax
80108090:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108095:	77 0f                	ja     801080a6 <loaduvm+0x8c>
      n = sz - i;
80108097:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809a:	8b 55 18             	mov    0x18(%ebp),%edx
8010809d:	29 c2                	sub    %eax,%edx
8010809f:	89 d0                	mov    %edx,%eax
801080a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801080a4:	eb 07                	jmp    801080ad <loaduvm+0x93>
    else
      n = PGSIZE;
801080a6:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801080ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b0:	8b 55 14             	mov    0x14(%ebp),%edx
801080b3:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801080b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801080b9:	89 04 24             	mov    %eax,(%esp)
801080bc:	e8 b9 f6 ff ff       	call   8010777a <p2v>
801080c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801080c4:	89 54 24 0c          	mov    %edx,0xc(%esp)
801080c8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801080cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d0:	8b 45 10             	mov    0x10(%ebp),%eax
801080d3:	89 04 24             	mov    %eax,(%esp)
801080d6:	e8 43 9e ff ff       	call   80101f1e <readi>
801080db:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801080de:	74 07                	je     801080e7 <loaduvm+0xcd>
      return -1;
801080e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801080e5:	eb 18                	jmp    801080ff <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801080e7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801080ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f1:	3b 45 18             	cmp    0x18(%ebp),%eax
801080f4:	0f 82 4b ff ff ff    	jb     80108045 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801080fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801080ff:	83 c4 24             	add    $0x24,%esp
80108102:	5b                   	pop    %ebx
80108103:	5d                   	pop    %ebp
80108104:	c3                   	ret    

80108105 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108105:	55                   	push   %ebp
80108106:	89 e5                	mov    %esp,%ebp
80108108:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
8010810b:	8b 45 10             	mov    0x10(%ebp),%eax
8010810e:	85 c0                	test   %eax,%eax
80108110:	79 0a                	jns    8010811c <allocuvm+0x17>
    return 0;
80108112:	b8 00 00 00 00       	mov    $0x0,%eax
80108117:	e9 c1 00 00 00       	jmp    801081dd <allocuvm+0xd8>
  if(newsz < oldsz)
8010811c:	8b 45 10             	mov    0x10(%ebp),%eax
8010811f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108122:	73 08                	jae    8010812c <allocuvm+0x27>
    return oldsz;
80108124:	8b 45 0c             	mov    0xc(%ebp),%eax
80108127:	e9 b1 00 00 00       	jmp    801081dd <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010812c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010812f:	05 ff 0f 00 00       	add    $0xfff,%eax
80108134:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108139:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010813c:	e9 8d 00 00 00       	jmp    801081ce <allocuvm+0xc9>
    mem = kalloc();
80108141:	e8 89 ab ff ff       	call   80102ccf <kalloc>
80108146:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108149:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010814d:	75 2c                	jne    8010817b <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010814f:	c7 04 24 2d 8c 10 80 	movl   $0x80108c2d,(%esp)
80108156:	e8 45 82 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010815b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010815e:	89 44 24 08          	mov    %eax,0x8(%esp)
80108162:	8b 45 10             	mov    0x10(%ebp),%eax
80108165:	89 44 24 04          	mov    %eax,0x4(%esp)
80108169:	8b 45 08             	mov    0x8(%ebp),%eax
8010816c:	89 04 24             	mov    %eax,(%esp)
8010816f:	e8 6b 00 00 00       	call   801081df <deallocuvm>
      return 0;
80108174:	b8 00 00 00 00       	mov    $0x0,%eax
80108179:	eb 62                	jmp    801081dd <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
8010817b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108182:	00 
80108183:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010818a:	00 
8010818b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010818e:	89 04 24             	mov    %eax,(%esp)
80108191:	e8 99 d0 ff ff       	call   8010522f <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108196:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108199:	89 04 24             	mov    %eax,(%esp)
8010819c:	e8 cc f5 ff ff       	call   8010776d <v2p>
801081a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801081a4:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801081ab:	00 
801081ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
801081b0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081b7:	00 
801081b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801081bc:	8b 45 08             	mov    0x8(%ebp),%eax
801081bf:	89 04 24             	mov    %eax,(%esp)
801081c2:	e8 d8 fa ff ff       	call   80107c9f <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801081c7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801081ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d1:	3b 45 10             	cmp    0x10(%ebp),%eax
801081d4:	0f 82 67 ff ff ff    	jb     80108141 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801081da:	8b 45 10             	mov    0x10(%ebp),%eax
}
801081dd:	c9                   	leave  
801081de:	c3                   	ret    

801081df <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801081df:	55                   	push   %ebp
801081e0:	89 e5                	mov    %esp,%ebp
801081e2:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801081e5:	8b 45 10             	mov    0x10(%ebp),%eax
801081e8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801081eb:	72 08                	jb     801081f5 <deallocuvm+0x16>
    return oldsz;
801081ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801081f0:	e9 a4 00 00 00       	jmp    80108299 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801081f5:	8b 45 10             	mov    0x10(%ebp),%eax
801081f8:	05 ff 0f 00 00       	add    $0xfff,%eax
801081fd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108202:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108205:	e9 80 00 00 00       	jmp    8010828a <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010820a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108214:	00 
80108215:	89 44 24 04          	mov    %eax,0x4(%esp)
80108219:	8b 45 08             	mov    0x8(%ebp),%eax
8010821c:	89 04 24             	mov    %eax,(%esp)
8010821f:	e8 d9 f9 ff ff       	call   80107bfd <walkpgdir>
80108224:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108227:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010822b:	75 09                	jne    80108236 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010822d:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108234:	eb 4d                	jmp    80108283 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108236:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108239:	8b 00                	mov    (%eax),%eax
8010823b:	83 e0 01             	and    $0x1,%eax
8010823e:	85 c0                	test   %eax,%eax
80108240:	74 41                	je     80108283 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108242:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108245:	8b 00                	mov    (%eax),%eax
80108247:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010824c:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
8010824f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108253:	75 0c                	jne    80108261 <deallocuvm+0x82>
        panic("kfree");
80108255:	c7 04 24 45 8c 10 80 	movl   $0x80108c45,(%esp)
8010825c:	e8 d9 82 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108261:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108264:	89 04 24             	mov    %eax,(%esp)
80108267:	e8 0e f5 ff ff       	call   8010777a <p2v>
8010826c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010826f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108272:	89 04 24             	mov    %eax,(%esp)
80108275:	e8 bc a9 ff ff       	call   80102c36 <kfree>
      *pte = 0;
8010827a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010827d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108283:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010828a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108290:	0f 82 74 ff ff ff    	jb     8010820a <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108296:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108299:	c9                   	leave  
8010829a:	c3                   	ret    

8010829b <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010829b:	55                   	push   %ebp
8010829c:	89 e5                	mov    %esp,%ebp
8010829e:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801082a1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801082a5:	75 0c                	jne    801082b3 <freevm+0x18>
    panic("freevm: no pgdir");
801082a7:	c7 04 24 4b 8c 10 80 	movl   $0x80108c4b,(%esp)
801082ae:	e8 87 82 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801082b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801082ba:	00 
801082bb:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801082c2:	80 
801082c3:	8b 45 08             	mov    0x8(%ebp),%eax
801082c6:	89 04 24             	mov    %eax,(%esp)
801082c9:	e8 11 ff ff ff       	call   801081df <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801082ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801082d5:	eb 48                	jmp    8010831f <freevm+0x84>
    if(pgdir[i] & PTE_P){
801082d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082da:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801082e1:	8b 45 08             	mov    0x8(%ebp),%eax
801082e4:	01 d0                	add    %edx,%eax
801082e6:	8b 00                	mov    (%eax),%eax
801082e8:	83 e0 01             	and    $0x1,%eax
801082eb:	85 c0                	test   %eax,%eax
801082ed:	74 2c                	je     8010831b <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801082ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801082f9:	8b 45 08             	mov    0x8(%ebp),%eax
801082fc:	01 d0                	add    %edx,%eax
801082fe:	8b 00                	mov    (%eax),%eax
80108300:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108305:	89 04 24             	mov    %eax,(%esp)
80108308:	e8 6d f4 ff ff       	call   8010777a <p2v>
8010830d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108310:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108313:	89 04 24             	mov    %eax,(%esp)
80108316:	e8 1b a9 ff ff       	call   80102c36 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010831b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010831f:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108326:	76 af                	jbe    801082d7 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108328:	8b 45 08             	mov    0x8(%ebp),%eax
8010832b:	89 04 24             	mov    %eax,(%esp)
8010832e:	e8 03 a9 ff ff       	call   80102c36 <kfree>
}
80108333:	c9                   	leave  
80108334:	c3                   	ret    

80108335 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108335:	55                   	push   %ebp
80108336:	89 e5                	mov    %esp,%ebp
80108338:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010833b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108342:	00 
80108343:	8b 45 0c             	mov    0xc(%ebp),%eax
80108346:	89 44 24 04          	mov    %eax,0x4(%esp)
8010834a:	8b 45 08             	mov    0x8(%ebp),%eax
8010834d:	89 04 24             	mov    %eax,(%esp)
80108350:	e8 a8 f8 ff ff       	call   80107bfd <walkpgdir>
80108355:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108358:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010835c:	75 0c                	jne    8010836a <clearpteu+0x35>
    panic("clearpteu");
8010835e:	c7 04 24 5c 8c 10 80 	movl   $0x80108c5c,(%esp)
80108365:	e8 d0 81 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
8010836a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836d:	8b 00                	mov    (%eax),%eax
8010836f:	83 e0 fb             	and    $0xfffffffb,%eax
80108372:	89 c2                	mov    %eax,%edx
80108374:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108377:	89 10                	mov    %edx,(%eax)
}
80108379:	c9                   	leave  
8010837a:	c3                   	ret    

8010837b <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010837b:	55                   	push   %ebp
8010837c:	89 e5                	mov    %esp,%ebp
8010837e:	53                   	push   %ebx
8010837f:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108382:	e8 b0 f9 ff ff       	call   80107d37 <setupkvm>
80108387:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010838a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010838e:	75 0a                	jne    8010839a <copyuvm+0x1f>
    return 0;
80108390:	b8 00 00 00 00       	mov    $0x0,%eax
80108395:	e9 fd 00 00 00       	jmp    80108497 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
8010839a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801083a1:	e9 d0 00 00 00       	jmp    80108476 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801083a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083b0:	00 
801083b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801083b5:	8b 45 08             	mov    0x8(%ebp),%eax
801083b8:	89 04 24             	mov    %eax,(%esp)
801083bb:	e8 3d f8 ff ff       	call   80107bfd <walkpgdir>
801083c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
801083c3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801083c7:	75 0c                	jne    801083d5 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
801083c9:	c7 04 24 66 8c 10 80 	movl   $0x80108c66,(%esp)
801083d0:	e8 65 81 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
801083d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083d8:	8b 00                	mov    (%eax),%eax
801083da:	83 e0 01             	and    $0x1,%eax
801083dd:	85 c0                	test   %eax,%eax
801083df:	75 0c                	jne    801083ed <copyuvm+0x72>
      panic("copyuvm: page not present");
801083e1:	c7 04 24 80 8c 10 80 	movl   $0x80108c80,(%esp)
801083e8:	e8 4d 81 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801083ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083f0:	8b 00                	mov    (%eax),%eax
801083f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083f7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801083fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083fd:	8b 00                	mov    (%eax),%eax
801083ff:	25 ff 0f 00 00       	and    $0xfff,%eax
80108404:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108407:	e8 c3 a8 ff ff       	call   80102ccf <kalloc>
8010840c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010840f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108413:	75 02                	jne    80108417 <copyuvm+0x9c>
      goto bad;
80108415:	eb 70                	jmp    80108487 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108417:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010841a:	89 04 24             	mov    %eax,(%esp)
8010841d:	e8 58 f3 ff ff       	call   8010777a <p2v>
80108422:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108429:	00 
8010842a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010842e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108431:	89 04 24             	mov    %eax,(%esp)
80108434:	e8 c5 ce ff ff       	call   801052fe <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108439:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010843c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010843f:	89 04 24             	mov    %eax,(%esp)
80108442:	e8 26 f3 ff ff       	call   8010776d <v2p>
80108447:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010844a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010844e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108452:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108459:	00 
8010845a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010845e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108461:	89 04 24             	mov    %eax,(%esp)
80108464:	e8 36 f8 ff ff       	call   80107c9f <mappages>
80108469:	85 c0                	test   %eax,%eax
8010846b:	79 02                	jns    8010846f <copyuvm+0xf4>
      goto bad;
8010846d:	eb 18                	jmp    80108487 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010846f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108479:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010847c:	0f 82 24 ff ff ff    	jb     801083a6 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108482:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108485:	eb 10                	jmp    80108497 <copyuvm+0x11c>

bad:
  freevm(d);
80108487:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010848a:	89 04 24             	mov    %eax,(%esp)
8010848d:	e8 09 fe ff ff       	call   8010829b <freevm>
  return 0;
80108492:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108497:	83 c4 44             	add    $0x44,%esp
8010849a:	5b                   	pop    %ebx
8010849b:	5d                   	pop    %ebp
8010849c:	c3                   	ret    

8010849d <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010849d:	55                   	push   %ebp
8010849e:	89 e5                	mov    %esp,%ebp
801084a0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801084a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801084aa:	00 
801084ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801084ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801084b2:	8b 45 08             	mov    0x8(%ebp),%eax
801084b5:	89 04 24             	mov    %eax,(%esp)
801084b8:	e8 40 f7 ff ff       	call   80107bfd <walkpgdir>
801084bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801084c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084c3:	8b 00                	mov    (%eax),%eax
801084c5:	83 e0 01             	and    $0x1,%eax
801084c8:	85 c0                	test   %eax,%eax
801084ca:	75 07                	jne    801084d3 <uva2ka+0x36>
    return 0;
801084cc:	b8 00 00 00 00       	mov    $0x0,%eax
801084d1:	eb 25                	jmp    801084f8 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801084d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d6:	8b 00                	mov    (%eax),%eax
801084d8:	83 e0 04             	and    $0x4,%eax
801084db:	85 c0                	test   %eax,%eax
801084dd:	75 07                	jne    801084e6 <uva2ka+0x49>
    return 0;
801084df:	b8 00 00 00 00       	mov    $0x0,%eax
801084e4:	eb 12                	jmp    801084f8 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801084e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e9:	8b 00                	mov    (%eax),%eax
801084eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084f0:	89 04 24             	mov    %eax,(%esp)
801084f3:	e8 82 f2 ff ff       	call   8010777a <p2v>
}
801084f8:	c9                   	leave  
801084f9:	c3                   	ret    

801084fa <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801084fa:	55                   	push   %ebp
801084fb:	89 e5                	mov    %esp,%ebp
801084fd:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108500:	8b 45 10             	mov    0x10(%ebp),%eax
80108503:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108506:	e9 87 00 00 00       	jmp    80108592 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010850b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010850e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108513:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108516:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108519:	89 44 24 04          	mov    %eax,0x4(%esp)
8010851d:	8b 45 08             	mov    0x8(%ebp),%eax
80108520:	89 04 24             	mov    %eax,(%esp)
80108523:	e8 75 ff ff ff       	call   8010849d <uva2ka>
80108528:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010852b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010852f:	75 07                	jne    80108538 <copyout+0x3e>
      return -1;
80108531:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108536:	eb 69                	jmp    801085a1 <copyout+0xa7>
    n = PGSIZE - (va - va0);
80108538:	8b 45 0c             	mov    0xc(%ebp),%eax
8010853b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010853e:	29 c2                	sub    %eax,%edx
80108540:	89 d0                	mov    %edx,%eax
80108542:	05 00 10 00 00       	add    $0x1000,%eax
80108547:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010854a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010854d:	3b 45 14             	cmp    0x14(%ebp),%eax
80108550:	76 06                	jbe    80108558 <copyout+0x5e>
      n = len;
80108552:	8b 45 14             	mov    0x14(%ebp),%eax
80108555:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108558:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010855b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010855e:	29 c2                	sub    %eax,%edx
80108560:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108563:	01 c2                	add    %eax,%edx
80108565:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108568:	89 44 24 08          	mov    %eax,0x8(%esp)
8010856c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108573:	89 14 24             	mov    %edx,(%esp)
80108576:	e8 83 cd ff ff       	call   801052fe <memmove>
    len -= n;
8010857b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010857e:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108581:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108584:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108587:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010858a:	05 00 10 00 00       	add    $0x1000,%eax
8010858f:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108592:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108596:	0f 85 6f ff ff ff    	jne    8010850b <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010859c:	b8 00 00 00 00       	mov    $0x0,%eax
}
801085a1:	c9                   	leave  
801085a2:	c3                   	ret    
