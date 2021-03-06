//
//  StackHelper.c
//  lwip
//
//  Created by 孔祥波 on 11/11/16.
//  Copyright © 2016 Kong XiangBo. All rights reserved.
//

#include "StackHelper.h"

#include <pthread.h>
struct netif netif;
struct tcp_pcb *listener;
// mananger tcp stack
static err_t netif_init_func (struct netif *netif);
static err_t netif_input_func (struct pbuf *p, struct netif *inp);



extern void lwip_init(void);
#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

//#   define DLog(...)
//#   define SLog(...)
#endif


void logLWIPParams()
{
#ifdef DEBUG
    //printf("lwip arguments",@__FILE__, __LINE__);
    fprintf(stdout,"TCP_MSS: %d\n",TCP_MSS);
    fprintf(stdout,"TCP_WND: %d\n",TCP_WND);
    fprintf(stdout,"TCP_QUEUE_OOSEQ: %d\n",TCP_QUEUE_OOSEQ);
    fprintf(stdout,"TCP_SND_BUF: %d\n",TCP_SND_BUF);
    fprintf(stdout,"TCP_SND_QUEUELEN: %d\n",TCP_SND_QUEUELEN);
    fprintf(stdout,"TCP_OVERSIZE: %d\n",TCP_OVERSIZE);
#endif
}
void lwiplog (const char *fmt, ...)
{
#ifdef DEBUG
    char buf[128];
    va_list vl;
    va_start(vl, fmt);
    vsnprintf(buf, 128, fmt, vl);
    va_end(vl);
    fprintf(stdout, "[%d]:%s\n",pthread_mach_thread_np(pthread_self()),buf);
    
#endif
    
}
void testLog(NSString *f,int line,char *format, ...)
{
#ifdef DEBUG
    va_list arg_ptr;
    va_start(arg_ptr, format);
    char content[128];
    vsnprintf(content, 128, format, arg_ptr);
    va_end(arg_ptr);
    
#endif
}
void surfLog(char *string,NSString *file,NSInteger line)
{
    
#ifdef DEBUG
    //NSLog(@"%s",string);
    //NSInteger line = 0 ;
    
   // [AxLogger log:[NSString stringWithFormat:@"%s",string] level:AxLoggerLevelInfo category:@"cfunc" file:file line:line ud:@{@"test":@"test"} tags:@[@"test"] time:[NSDate date]];
#endif
}
struct tcp_pcb *init_lwip(netif_output_fn output,netif_input_fn input)
{
    
    lwip_init();
    ip_addr_t addr;
    addr.addr = 0x00000000UL;//0xf0000001;//0202a8c0 ;//0xc0a80202 ;// ;
    ip_addr_t netmask;
    netmask.addr = 0xffffffff;
    ip_addr_t gw;
    ip_addr_set_any(&gw);
    logLWIPParams();
    // init netif
    if (!netif_add(&netif, &addr, &netmask, &gw, NULL, netif_init_func, input)) {
        surfLog("netif_add failed",@__FILE__, __LINE__);
        
    }
    netif.output = output;
    netif_set_up(&netif);
    // set netif pretend TCP
    netif_set_pretend_tcp(&netif, 1);
    // set netif default
    netif_set_default(&netif);
    
    testLog(@__FILE__, __LINE__,"netif_mtu :%d",netif.mtu);
    
    struct tcp_pcb *l = tcp_new();
    
    testLog(@__FILE__, __LINE__,"tcp_pcb %p",l);
    if (!l) {
        //BLog(BLOG_ERROR, "tcp_new failed");
        surfLog("tcp_new failed",@__FILE__, __LINE__);
        
    }
    // bind listener
    if (tcp_bind_to_netif(l, "ho0") != ERR_OK) {
        //BLog(BLOG_ERROR, "tcp_bind_to_netif failed");
        surfLog("tcp_bind_to_netif failed",@__FILE__, __LINE__);
        tcp_close(l);
        
    }
    // listen listener
    if (!(listener = tcp_listen(l))) {
        surfLog( "tcp_listen failed",@__FILE__, __LINE__);
        tcp_close(l);
        
    }
    //printf("################################ 12skfjksdjfklsj");
    // setup listener accept handler
    //tcp_accept(listener, listener_accept_func);
    //testLog(@__FILE__, __LINE__,"tcp_accept %p",listener_accept_func);
    return  listener;
}

static err_t netif_init_func (struct netif *netif)
{
    surfLog("netif func init",@__FILE__, __LINE__);
    
    netif->name[0] = 'h';
    netif->name[1] = 'o';
    
    //netif->output_ip6 = netif_output_ip6_func;
    
    return ERR_OK;
}
static err_t netif_input_func (struct pbuf *p, struct netif *inp)
{
    testLog(@__FILE__,__LINE__,"pbuf:%p netif:%p",p,inp);
    uint8_t ip_version = 0;
    if (p->len > 0) {
        ip_version = (((uint8_t *)p->payload)[0] >> 4);
    }
    
    switch (ip_version) {
        case 4: {
            return  ip_input(p, inp);//ip_input will free pbuf
            
        } break;
        case 6: {
            printf("don't support ipv6");
            //pbuf_free(p);
            //return ERR_ARG;
            //            if (options.netif_ip6addr) {
            //                return ip6_input(p, inp);
            //            }
        } return -1;
    }
    
    pbuf_free(p);
    return ERR_OK;
}

void inputData(NSData *data,NSInteger len)
{
    struct pbuf *p = pbuf_alloc(PBUF_RAW,len,PBUF_POOL);
    //need pandun
    //        let a = UnsafeMutablePointer<pbuf>.init()
    //        if  {//p != UnsafeMutablePointer<SFPub>
    //
    //        }
    //AxLogger.log("input packet srcport \(sport)",level: .Debug)
    if (pbuf_take(p,data.bytes ,len) !=  0){
        //AxLogger.log("error",level:.Error)
        DLog(@"pbuf_take error");
    }
    //AxLogger.log("input pbuf data length:\(len)",level: .Debug)
    if (input(p) != 0){
        //AxLogger.log("device read: input failed",level: .Debug)
        //fatalError()
        DLog(@"input error");
    }
    
    
}





//(void *arg, struct tcp_pcb *tpcb)

void nagle_disable(struct tcp_pcb*pcb){
    tcp_nagle_disable(pcb);
}
void config_tcppcb(struct tcp_pcb*pcb, void *client)
{
    tcp_nagle_disable(pcb);
    //tcp_nagle_enable(pcb);
    tcp_arg(pcb, client);

    
}







#pragma mark -
#pragma makr lwip micro
uint16_t snd_buf(struct tcp_pcb *pcb)
{
    return tcp_sndbuf(pcb);
}
#pragma mark -
#pragma mark BADVPN
BAddr BAddr_MakeIPv4 (uint32_t ip, uint16_t port)
{
    BAddr addr;
    addr.type = BADDR_TYPE_IPV4;
    addr.ipv4.ip = ip;
    addr.ipv4.port = port;
    return addr;
}

void BAddr_InitIPv4 (BAddr *addr, uint32_t ip, uint16_t port)
{
    *addr = BAddr_MakeIPv4(ip, port);
}
BAddr baddr_from_lwip (int is_ipv6, const ipX_addr_t *ipx_addr, uint16_t port_hostorder)
{
    BAddr addr;
    if (is_ipv6) {
        //BAddr_InitIPv6(&addr, (uint8_t *)ipx_addr->ip6.addr, hton16(port_hostorder));
        surfLog("can't support ipv6",@__FILE__, __LINE__);
    } else {
        BAddr_InitIPv4(&addr, ipx_addr->ip4.addr, hton16(port_hostorder));
    }
    return addr;
}


void BIPAddr_InitIPv4 (BIPAddr *addr, uint32_t ip)
{
    addr->type = BADDR_TYPE_IPV4;
    addr->ipv4 = ip;
}
void BAddr_Print (BAddr *addr, char *out)
{
}
err_t input(struct pbuf *p)
{
    return netif.input(p,&netif);
}
void tcp_accepted_c(struct tcp_pcb *pcb)
{
    tcp_accepted(pcb);
}
ipX_addr_t local_ip(struct tcp_pcb *pcb)
{
    return pcb->local_ip;
}
int int2ip(uint32_t ip,char *p)
{
    
    sprintf(p, "%d.%d.%d.%d",
            (ip ) & 0xFF,
            (ip >> 8) & 0xFF,
            (ip >>  16) & 0xFF,
            (ip >> 24) & 0xFF);
    return 0;
}
BOOL isHTTP(struct tcp_pcb *pcb, uint32_t ip)
{
    char src[16];
    char proxy[16];
    int2ip(pcb->local_ip.ip4.addr,src);
    int2ip(ip,proxy);
    
    testLog(@__FILE__, __LINE__,"pcb->local_ip.ip4.addr :%s == ip :%s",src,proxy);
    
    if (pcb->local_ip.ip4.addr == ip) {
        
        return true;
    }else{
        //        if (pcb->local_port == 80){
        //            return true;
        //        }else {
        //            return false;
        //        }
        return  false;
    }
}
void config_netif (struct netif *netif)
{
    surfLog("netif func init",@__FILE__, __LINE__);
    
    netif->name[0] = 'h';
    netif->name[1] = 'o';
}
static void tcp_remove(struct tcp_pcb* pcb_list)
{
    surfLog("tcp_remove", @__FILE__, __LINE__);
    struct tcp_pcb *pcb = pcb_list;
    struct tcp_pcb *pcb2;
    
    while(pcb != NULL)
    {
        pcb2 = pcb;
        pcb = pcb->next;
        tcp_abort(pcb2);
    }
}
const  char* pcbStatus(struct tcp_pcb* pcb)
{
    return tcp_debug_state_str(pcb ->state);
}
enum tcp_state  pcbStat(struct tcp_pcb*pcb){
    return pcb ->state;
}

int tcp_write_check(SFPcb pcb)
{
    if (pcb->state == CLOSE_WAIT) {
        lwipassertlog("pcb %p state:CLOSE_WAIT",pcb);
    }
    if (pcb->snd_queuelen != 0) {
        int x = pcb->unacked != NULL || pcb->unsent != NULL;
        if (x == 0){
            return -2;
        }
        //assert();
    } else {
        int x = pcb->unacked == NULL && pcb->unsent == NULL;
        if (x == 0){
            return -1;
        }
        
    }
    
    return 0;
}

#include "tcp_impl.h"
void closeTW(){
    tcp_remove(tcp_tw_pcbs);
}
void closeLWIP()
{
    tcp_remove(tcp_bound_pcbs);
    tcp_remove(tcp_tw_pcbs);
    //tcp_remove(tcp_active_pcbs);
    
}
void pcbinfo(SFPcb pcb, uint32_t *srcip,uint32_t *dstip, uint16_t *sport , uint16_t *dport)
{
    *srcip = pcb->local_ip.ip4.addr;
    *sport = pcb->local_port;
    
    *dstip = pcb->remote_ip.ip4.addr;
    *dport = pcb->remote_port;
}
